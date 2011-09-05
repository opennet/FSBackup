#!/bin/sh
# Script for backup SQL tables from SQLite
# Скрипт для бэкапа данных хранимых в SQLite
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001-2004 by Maxim Chirkov. <mc@tyumen.ru>
#
# For restore data type:
# Восстановление производится с помощью команды: 
#  cat <backupfile> |sqlite <path_to_db_file>
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
#
#-------------------

backup_method="notdb"

#-------------------
# List of databases (full path delimited by spaces)
# Список включаемых или исключаемых из бэкапа баз (полный путь к базе), через пробел.
# Таблицы указываются в в переменной backup_tables_list в виде: имя_базы:имя_таблицы
# Внимание, при выборе метода "db" требует полное перечисление всех 
# помещаемых в бэкап баз и таблиц в переменную backup_tables_list
#-------------------

backup_db_list="/home/test/test /home/web/work_db /home/rt/rt3"
backup_tables_list="test rt3:Links"

#-------------------
# Directory to store SQL backup. You must have enought free disk space to store 
# all data from you SQL server.
# Директория куда будет помещен бэкап данных с SQL сервера. 
# Внимание !!! Должно быть достаточно свободного места для бэкапа всех 
# выбранных БД.
#-------------------

backup_path="/usr/local/fsbackup/sys_backup"

#-------------------
# Full path of sqlite program.
# Путь к программе sqlite
#-------------------

backup_progdump_path="/usr/local/bin"

############################################################################

if [ -n "$backup_progdump_path" ]; then
    backup_progdump_path="$backup_progdump_path/"
fi

#-------------------------------------------------------------------------
# Полный бэкап для SQLite

if [ "_$backup_method" = "_full" ]; then
    echo "Creating full backup of all SQLite databases."
    for cur_db in $backup_db_list; do
	cur_db_name=`basename $cur_db`
	if [ -f "$cur_db" ]; then
	    ${backup_progdump_path}sqlite $cur_db .dump |gzip > $backup_path/$backup_name-$cur_db_name-sqlite.gz
	else
	    echo "DB $cur_db not found"
	fi
    done
    exit

fi

#-------------------------------------------------------------------------
# Бэкап указанных баз для SQLite
if [ "_$backup_method" = "_db" ]; then
    echo "Creating full backup of $backup_tables_list SQLite databases."

    for cur_db in $backup_db_list; do
	cur_db_name=`basename $cur_db`
	if [ -f "$cur_db" ]; then
	    echo "Proccessing $cur_db"
	    flag=0
	    for cur_acl in $backup_tables_list; do
		if [ "_$cur_acl" = "_$cur_db_name" ]; then
		    flag=1
		fi
	    done
    	
	    if [ $flag -eq 1 ]; then
	        echo "Dumping $cur_db_name"
	        ${backup_progdump_path}sqlite $cur_db .dump |gzip > $backup_path/$backup_name-$cur_db_name-sqlite.gz
	    else
		rm -f $backup_path/$backup_name-$cur_db_name-sqlite
	        for cur_db_table in `${backup_progdump_path}sqlite $cur_db .tables`; do
		    for cur_acl in $backup_tables_list; do
			if [ "_$cur_acl" = "_$cur_db_name:$cur_db_table" ]; then
			    echo "  Dumping $cur_db_name:$cur_db_table"
			    ${backup_progdump_path}sqlite $cur_db ".dump $cur_db_table" >> $backup_path/$backup_name-$cur_db_name-sqlite
			fi
		    done
		done	    
		if [ -f "$backup_path/$backup_name-$cur_db_name-sqlite" ]; then
		    gzip -f $backup_path/$backup_name-$cur_db_name-sqlite
		fi
	    fi
	else
	    echo "DB $cur_db not found"
	fi
    done
    exit

fi


#-------------------------------------------------------------------------
# Бэкап всех баз кроме указанных для Postgresql
if [ "_$backup_method" = "_notdb" ]; then
    echo "Creating full backup of all SQLite databases except databases $backup_tables_list."

    for cur_db in $backup_db_list; do
	cur_db_name=`basename $cur_db`
	if [ -f "$cur_db" ]; then
	    echo "Proccessing $cur_db"
	    flag=0
	    for cur_acl in $backup_tables_list; do
		if [ "_$cur_acl" = "_$cur_db_name" ]; then
		    flag=1
		fi
	    done
    	    
	    if [ $flag -eq 1 ]; then
		echo "Skiping $cur_db_name"
	    else
		rm -f $backup_path/$backup_name-$cur_db_name-sqlite
		for cur_db_table in `${backup_progdump_path}sqlite $cur_db .tables`; do
		    flag=0
		    for cur_acl in $backup_tables_list; do
			if [ "_$cur_acl" = "_$cur_db_name:$cur_db_table" ]; then
			    echo "  Skiping $cur_db_name:$cur_db_table"
			    flag=1
			fi
		    done

		    if [ $flag -eq 0 ]; then
			${backup_progdump_path}sqlite $cur_db ".dump $cur_db_table" >> $backup_path/$backup_name-$cur_db_name-sqlite
    		    fi
	    	done	    
	    
		if [ -f "$backup_path/$backup_name-$cur_db_name-sqlite" ]; then
		    gzip -f $backup_path/$backup_name-$cur_db_name-sqlite
		fi
	    fi
	else
	    echo "DB $cur_db not found"
	fi
    done
    exit

fi

echo "Configuration error. Not valid parameters in backup_method or backup_sqltype."


