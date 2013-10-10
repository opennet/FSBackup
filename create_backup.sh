#!/bin/sh
# Backup planner running from crontab.
# Скрипт для запуска backup подсистемы из crontab.
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>
#
# Пример строки для crontab:
#
#18 4 * * * /usr/local/fsbackup/create_backup.sh| mail -s "`uname -n` backup report" root

#--------------------------------------
# Path where fsbackup installed.
# Директория где установлена программа.
#--------------------------------------

backup_path="/usr/local/fsbackup"


#--------------------------------------
# List of fsbackup configuration files, delimited by spaces.
# Directories for saving backup in each configuration file should differ
# ($cfg_remote_path, $cfg_local_path).
#
# Список файлов конфигурации, разделенных пробелом.
# Директории для сохранения бэкапа в каждом конфигурационном файле
# должны отличаться ($cfg_remote_path, $cfg_local_path), сохранение в одной и
# тойже директории нескольких, описанных разными .conf файлами, бэкапов не
# допустимо.

#--------------------------------------

config_files="cfg_example cfg_example_users cfg_example_sql"


#--------------------------------------
# 1 - run mysql_backup.sh script (you need edit mysql_backup.sh first!), 0 - not run.
# Флаг бэкапа MySQL таблиц, запускается требующий предварительной настройки
# скрипт ./scripts/mysql_backup.sh, 1 - запускать, 0 - не запускать.
#--------------------------------------

backup_mysql=0

#--------------------------------------
# 1 - run pgsql_backup.sh script (you need edit pgsql_backup.sh first!), 0 - not run.
# Флаг бэкапа PostgreSQL таблиц, запускается требующий предварительной настройки
# скрипт ./scripts/pgsql_backup.sh, 1 - запускать, 0 - не запускать.
#--------------------------------------

backup_pgsql=0

#--------------------------------------
# 1 - run sqlite_backup.sh script (you need edit sqlite_backup.sh first!), 0 - not run.
# Флаг бэкапа SQLite таблиц, запускается требующий предварительной настройки
# скрипт ./scripts/sqlite_backup.sh, 1 - запускать, 0 - не запускать.
#--------------------------------------

backup_sqlite=0


#--------------------------------------
# 1 - run sysbackup.sh script (you need edit sysbackup.sh first!), 0 - not run.
# Флаг бэкапа параметров системы, запускается требующий предварительной
# настройки скрипт ./scripts/sysbackup.sh, 1 - запускать, 0 - не запускать.
#--------------------------------------

backup_sys=0

#--------------------------------------
# 1 - run mount-windows-share.sh script (you need edit mount-windows-share.sh first!), 0 - not run.
#
# Флаг запуска скрипта, который маунтит расшаренную папку Windows.
# Требуется предварительная настройка скрипта ./scripts/mount-windows-share.sh,
# 1 - запускать, 0 - не запускать.
#--------------------------------------
mount_winshare=0

#############################################################################
# Защита от повторного запуска двух копий fsbackup.pl
IDLE=`ps auxwww | grep fsbackup.pl | grep -v grep`
if [ "$IDLE" != "" ];  then
    echo "!!!!!!!!!!!!!!! `date` Backup dup"
    exit
fi


#cd $backup_path

# Оставил ulimit после тестирования, на всякий случай.
#ulimit -f 512000;ulimit -d 20000;ulimit -c 100;ulimit -m 25000;ulimit -l 15000

# Сохраняем MySQL базы
if [ $backup_mysql -eq 1 ]; then
    ./scripts/mysql_backup.sh
fi

# Сохраняем PostgreSQL базы
if [ $backup_pgsql -eq 1 ]; then
    ./scripts/pgsql_backup.sh
fi

# Сохраняем SQLite базы
if [ $backup_sqlite -eq 1 ]; then
    ./scripts/sqlite_backup.sh
fi

# Сохраняем системные параметры
if [ $backup_sys -eq 1 ]; then
    ./scripts/sysbackup.sh
fi

# Маунтим Windows шару (ждём пока она появится)
if [ $mount_winshare -eq 1 ]; then
    ./scripts/mount-windows-share.sh || exit 1
fi

# Бэкап.
for cur_conf in $config_files; do
    ./fsbackup.pl ./$cur_conf
    next_iter=`echo "$config_files"| grep "$cur_conf "`
    if [ -n "$next_iter" ]; then
	sleep 600 # Засыпаем на 10 минут, даем процессору остыть :-)
    fi
done

# Отмаунчиваем Windows шару
if [ $mount_winshare -eq 1 ]; then
    ./scripts/mount-windows-share.sh umount
fi

