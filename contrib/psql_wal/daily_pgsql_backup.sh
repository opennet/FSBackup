#!/bin/sh
#
# Created by Molchanov Alexander <xorader@mail.ru> 2010
# ver 0.2
#
# Этот скрипт переносит WAL-файлы (Write-Ahead Logs) Postgres'а на FTP backup сервер.
# WAL-файлы - это SQL история всех изменений которые делает Postgres и которые пишутся ПОСТОЯННО.

# Для работы данного скрипта необходимо
# 1) Установить ncftp (http://www.ncftp.com/)
#    For gentoo: emerge -v net-ftp/ncftp
# 2)
#   $ mkdir -p /home/require_for_sql_backup/pgsql_wal /home/require_for_sql_backup/tmp_wal
#   $ chown postgres -R /home/require_for_sql_backup
# 3) добавить следующую строку в postgresql.conf и перезапустить postgres:
#   archive_command = 'cp -i %p /home/require_for_sql_backup/pgsql_wal/%f < /dev/null'

# Скрипт daily_pgsql_backup.sh рекомендуется запускать каждый час.
# Пример строки для cron: 47 */1 * * * /usr/local/fsbackup/scripts/daily_pgsql_backup.sh| mail -s "`uname -n` WAL backup report" root

##############################
# Полезные ссылки:
#  http://www.postgresql.org/docs/current/static/continuous-archiving.html
#  http://wiki.opennet.ru/HotBackupPostgreSQL
#
# Как восстанавливать из WAL-файлов читайте в конце этого скрипта
#-------------------------------------------------


backup_name="hostname_pgsql_daily"
backup_suuser="postgres"
# можно просто использовать: backup_db="template1"
backup_db="dbname"
wal_dir="/home/require_for_sql_backup/pgsql_wal"
tmp_dir="/home/require_for_sql_backup/tmp_wal"

cfg_remote_host="fsbackupserver.company.net"
cfg_remote_login="fsbackup"
cfg_remote_path="/$backup_name"
cfg_remote_password="xxxxxxxxxxx"

####
#----------------------------------------------------------------

date=`date +%F`

# test running fsbackup backup
if ps auxw | grep create_backup.sh | grep -v grep >/dev/null
then
	if [ x"$1" != "xforce" ]
	then
		echo "Finded running create_backup.sh. Exit now."
		exit 1
	fi
fi

#

count="1"

tarfile="${backup_name}_${date}-${count}.tar.gz"
while [ x`ncftpls -1 -u $cfg_remote_login -p $cfg_remote_password -F ftp://$cfg_remote_host/$cfg_remote_path/ | grep "$tarfile"` != x ]
do
	count=$(($count+1))
	tarfile="${backup_name}_${date}-${count}.tar.gz"
done

echo "Creating daily backup of WAL (Write-Ahead Logs) PostgreSQL databases."
echo "$tarfile :"

su - ${backup_suuser} -c "psql -c \"SELECT pg_start_backup('${backup_name}_${date}');\" ${backup_db}"
su - ${backup_suuser} -c "psql -c \"SELECT pg_stop_backup();\" ${backup_db}"

mv $wal_dir/* $tmp_dir
sleep 3
cd $tmp_dir
lastfile=`ls -1 | sort | tail -n 1`
echo "CHECKPOINT TIME:  `LC_ALL=C date`" > ${lastfile}.backup
tar cvzf - * | ncftpput -u $cfg_remote_login -p $cfg_remote_password -F -c $cfg_remote_host $cfg_remote_path/$tarfile
if [ $? -eq 0 ]
then
	rm -vf $tmp_dir/*
else
        echo "Some error during create WAL-tarfile and upload it to ftp server"
fi

date
echo "daily_pgsql_backup.sh done."
exit 0

####################################################
# Как восстанавливать из WAL-файлов:
# Recovering using a Continuous Archive Backup (WAL)

##########
# simple:

# 1. restore pgSQL from fsbackup backup
# 2. untar all daily backups to /home/require_for_sql_backup/pgsql_wal
# 3. create recovery.conf with: restore_command = 'cp /home/require_for_sql_backup/pgsql_wal/%f %p'
# 4. restart postgres
# 5. wait file recovery.done

##########
# full info:

# Stop the server, if it's running.

# If you have the space to do so, copy the whole cluster data directory and any tablespaces to a temporary location in case you need them later. Note that this precaution will require that you have enough free space on your system to hold two copies of your existing database. If you do not have enough space, you need at the least to copy the contents of the pg_xlog subdirectory of the cluster data directory, as it might contain logs which were not archived before the system went down.

# Clean out all existing files and subdirectories under the cluster data directory and under the root directories of any tablespaces you are using.

# Restore the database files from your base backup. Be careful that they are restored with the right ownership (the database system user, not root!) and with the right permissions. If you are using tablespaces, you should verify that the symbolic links in pg_tblspc/ were correctly restored.

# Remove any files present in pg_xlog/; these came from the backup dump and are therefore probably obsolete rather than current. If you didn't archive pg_xlog/ at all, then recreate it, being careful to ensure that you re-establish it as a symbolic link if you had it set up that way before.

# If you had unarchived WAL segment files that you saved in step 2, copy them into pg_xlog/. (It is best to copy them, not move them, so that you still have the unmodified files if a problem occurs and you have to start over.)

# Create a recovery command file recovery.conf in the cluster data directory (see Recovery Settings). You might also want to temporarily modify pg_hba.conf to prevent ordinary users from connecting until you are sure the recovery has worked.

# Start the server. The server will go into recovery mode and proceed to read through the archived WAL files it needs. Should the recovery be terminated because of an external error, the server can simply be restarted and it will continue recovery. Upon completion of the recovery process, the server will rename recovery.conf to recovery.done (to prevent accidentally re-entering recovery mode in case of a crash later) and then commence normal database operations.

# Inspect the contents of the database to ensure you have recovered to where you want to be. If not, return to step 1. If all is well, let in your users by restoring pg_hba.conf to normal.

# Example recovery.conf:  restore_command = 'cp /mnt/server/archivedir/%f %p'

##########


