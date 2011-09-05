#!/bin/sh
# Синхронизация домашней директории пользователя "user_name" и 
# базы "database_name" на удаленный хост.

CUR_PATH=/home/user/backup_rsync
date

# Предотвращаем съедание процессом всей памяти.
ulimit -v 200000

# Исключаем одновременный запуск двух rsync процессов.
IDLE=`ps -auxwww | grep "rsync" | grep -vE "grep|rsync_backup"`
if [ "$IDLE" != "" ];  then
    echo "FATAL DUP"| mail -s "FATAL RSYNC BACKUP DUP" admins@testhost.ru
exit
fi


/usr/local/pgsql/bin/pg_dump -c database_name |/usr/bin/gzip > ~/sql_dump.sql.gz

export RSYNC_RSH="ssh -c arcfour -o Compression=no -x"

# -n
/usr/local/bin/rsync -a -z -v --delete --max-delete=600 --bwlimit=50 \
  --backup --backup-dir=/home/backup_user/BACKUP_OLD_user_name \
  --exclude-from=$CUR_PATH/rsync.exclude \
  /home/user_name/ backup_user@backuphost.ru:/home/backup_user/BACKUP_user_name/
  
  
RETCODE=$?
if [ $RETCODE -ne 0 -a $RETCODE -ne 24 ]; then
	echo "Err code=$RETCODE"| mail -s "FATAL RSYNC BACKUP" admin@testhost.ru
fi
echo RET: $RETCODE
date
