#!/bin/sh
# Script for backup SQL tables from MySQL
# Скрипт для бэкапа данных хранимых в Mysql.
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>
#
# For restore data type:
# Восстановление производится с помощью команды: mysql < backupfile
#

#-------------------
# Name of backup, single word.
# Имя бэкапа.
#-------------------

backup_name="test_host"


#-------------------
# Backup method:
# full - backup full DB's structure and data.
# db   - backup full DB's structure and data only for 'backup_db_list' databases.
# notdb- backup full DB's structure and data for all DB's, except 
#        data of 'backup_db_list' databases.
#
# Метод бэкапа:
# full	- полный бэкап всех баз (рекомендуется), 
#	 аналог запуска pg_dumpall или mysqldump --all-databases --all
#
# db    - бэкап только указанных в backup_db_list баз данных, записи по 
#	  реконструкции баз и таблиц записываются для всех баз на SQL сервере.
# notdb  - бэкап всех баз, кроме указанных в backup_db_list, записи по 
#	   реконструкции баз и таблиц записываются для всех баз на SQL сервере.
#          Возможно исключение из бэкапа  выборочных таблиц, тогда формат 
#	   списка исключаемых таблиц задается в виде: 
#	   "trash_db1 trash_db2:table1 trash_db2:table2"
#          - производим бэкап всех баз, коме базы trash_db1 и таблиц table1 и 
#	   table2 базы trash_db2.
#
#-------------------

backup_method="notdb"


#-------------------
# List of databases (delimited by spaces)
# Список включаемых или исключаемых из бэкапа баз, через пробел.
# Таблицы указываются в виде: имя_базы:имя_таблицы
#-------------------

backup_db_list="aspseek trash:cache_table1 trash:cache_table2 mnogosearch"


#-------------------
# Auth information for MySQL.
# Имя пользователя и пароль для соединения с Mysql, для PostgreSQL скрипт 
# должен запускаться из-под пользователя с правами полного доступа к базам PostgreSQL.
#-------------------

backup_mysqluser=""
backup_mysqlpassword=""
backup_mysqlhost="localhost"


#-------------------
# Directory to store SQL backup. You must have enought free disk space to store 
# all data from you SQL server.
# Директория куда будет помещен бэкап данных с SQL сервера. 
# Внимание !!! Должно быть достаточно свободного места для бэкапа всех 
# выбранных БД.
#-------------------

backup_path="/usr/local/fsbackup/sys_backup"


#-------------------
# Full path of mysql programs.
# Путь к программам mysql
#-------------------

backup_progdump_path="/usr/local/mysql/bin"

#-------------------
# Extra flags for mysqldump program. 
# -c (--complete-insert) - Use complete insert statements.
# Дополнительные параметры для pg_dump
# -c - формировать бэкап данных в виде INSERT комманд, с указанием названий
#      столбцов. Если скорость восстановления из бэкапа и размер бэкапа
#      более важны, и совместимостью с другими СУБД можно пренебречь, 
#      используйте: extra_mysqldump_flag=""
#-------------------

extra_mysqldump_flag="--complete-insert"

############################################################################

if [ -n "$backup_progdump_path" ]; then
    backup_progdump_path="$backup_progdump_path/"
fi

#-------------------------------------------------------------------------
# Полный бэкап для Mysql
if [ "_$backup_method" = "_full" ]; then
    echo "Creating full backup of all MySQL databases."
    ${backup_progdump_path}mysqldump --all --add-drop-table --all-databases --force --no-data $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost > $backup_path/$backup_name-struct-mysql
    ${backup_progdump_path}mysqldump --all-databases --all --add-drop-table --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost |gzip > $backup_path/$backup_name-mysql.gz
    exit
fi

#-------------------------------------------------------------------------
# Бэкап указанных баз для Mysql
if [ "_$backup_method" = "_db" ]; then
    echo "Creating full backup of $backup_db_list MySQL databases."
    ${backup_progdump_path}mysqldump --all --add-drop-table --all-databases --force --no-data $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost > $backup_path/$backup_name-struct-mysql
    cat /dev/null > $backup_path/$backup_name-mysql

    for cur_db in $backup_db_list; do
	echo "Dumping $cur_db..."
	cur_db=`echo "$cur_db" | awk -F':' '{if (\$2 != ""){print \$1, \$2}else{print \$1}}'`
	${backup_progdump_path}mysqldump --all --add-drop-table --databases --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost $cur_db	>> $backup_path/$backup_name-mysql
    done
    gzip -f $backup_path/$backup_name-mysql
    exit
fi

#-------------------------------------------------------------------------
# Бэкап всех баз кроме указанных для Mysql
if [ "_$backup_method" = "_notdb" ]; then
    echo "Creating full backup of all MySQL databases except databases $backup_db_list."
    ${backup_progdump_path}mysqldump --all --add-drop-table --all-databases --force --no-data $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost > $backup_path/$backup_name-struct-mysql
    cat /dev/null > $backup_path/$backup_name-mysql
    
    for cur_db in `${backup_progdump_path}mysqlshow --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost | tr -d ' |'|grep -v -E '^Databases$|^\+\-\-\-'`; do

	grep_flag=`echo " $backup_db_list"| grep " $cur_db:"`
	if [ -n "$grep_flag" ]; then
# Исключение таблиц для данной базы
	    ${backup_progdump_path}mysqldump --all --add-drop-table --databases --no-create-info --no-data --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost $cur_db >> $backup_path/$backup_name-mysql

	    for cur_db_table in `${backup_progdump_path}mysqlshow --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost $cur_db| tr -d ' |'|grep -v -E '^Tables$|^Database\:|^\+\-\-\-'`; do

		flag=1
		for cur_ignore in $backup_db_list; do
		    if [ "_$cur_ignore" = "_$cur_db:$cur_db_table" ]; then
			flag=0
		    fi
    		done

		if [ $flag -gt 0 ]; then
		    echo "Dumping $cur_db:$cur_db_table..."
		    ${backup_progdump_path}mysqldump --all --add-drop-table --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost $cur_db $cur_db_table >> $backup_path/$backup_name-mysql

		else
		    echo "Skiping $cur_db:$cur_db_table..."
		fi
	    done
	else
# Исключение базы
	    flag=1
	    for cur_ignore in $backup_db_list; do
		if [ "_$cur_ignore" = "_$cur_db" ]; then
		    flag=0
		fi
	    done

	    if [ $flag -gt 0 ]; then
		echo "Dumping $cur_db..."
		${backup_progdump_path}mysqldump --all --add-drop-table --databases --force $extra_mysqldump_flag --password=$backup_mysqlpassword --user=$backup_mysqluser --host=$backup_mysqlhost $cur_db >> $backup_path/$backup_name-mysql
	    else
		echo "Skiping $cur_db..."
	    fi
	fi
    done
    gzip -f $backup_path/$backup_name-mysql
    exit
fi

echo "Configuration error. Not valid parameters in backup_method or backup_sqltype."


