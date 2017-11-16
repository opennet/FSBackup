#!/bin/sh
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>
# Changed by Molchanov Alexander <xorader@mail.ru (2012)
# Ver 1.5
#
# Script for backup SQL tables from PostreSQL
# Скрипт для бэкапа данных хранимых в PostgreSQL
#
# For restore data type:
# Восстановление производится с помощью команды: psql -d template1 -f backupfile
#

#-------------------
# Name of backup, single word.
# Имя бэкапа.
#-------------------

backup_name="hostname_pgsql"

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

backup_method="full"

#-------------------
# List of databases (delimited by spaces)
# Список включаемых или исключаемых из бэкапа баз, через пробел.
# Таблицы указываются в виде: имя_базы:имя_таблицы
#-------------------

backup_db_list="aspseek trash:cache_table1 trash:cache_table2 mnogosearch"


#-------------------
# Auth information for PgSQL.
# Имя пользователя и пароль для соединения с PostgreSQL
#-------------------
backup_sqluser=""
backup_sqlpassword=""
backup_sqlhost=""
# default PG sqlport is 5432
backup_sqlport="5432"

# File $PGPASS_FILE format: hostname:port:database:username:password
# don't change below line (не меняйте строчку ниже, если не понимаете зачем она)!
PGPASS_FILE="/root/.pgpass"

#-------------------
# Change to user (by su) before run 'pgdump' util
# Запускать 'pgdump' из под пользователя:
#backup_suuser="postgres"
backup_suuser=""

#
# Chown by $backup_suuser the $backup_path directory
# Сменить права директории $backup_path и $PGPASS_FILE файла
# (лучше это сделать вручную, что бы в дальнейшем не было конфликтов)
chown_by_suuser=0

# Если используется $chown_by_suuser, то нужно сменить PGPASS_FILE на '~$backup_suuser/.pgpass'
# (то есть на '~postgres/.pgpass', а лучше точный путь до домашнего каталога $backup_suuser)

#-------------------
# Сделать последний WAL (Write-Ahead Logs) бакап и сделать rotate в конце.
# Перед этим положив эти скрипты из папки 'contrib/psql_wal' дистрибутива в /usr/local/fsbackup/scripts
# Обязательно настроить эти скрипты (подредактировав их вначале)
# Инструкции, что такое WAL и как использовать находятся в комментариях файла contrib/psql_wal/daily_pgsql_backup.sh
wal_backup=0

#-------------------
# Directory to store SQL backup. You must have enought free disk space to store
# all data from you SQL server.
# Директория куда будет помещен бэкап данных с SQL сервера.
# Внимание !!! Должно быть достаточно свободного места для бэкапа всех
# выбранных БД.
#-------------------

backup_path="/usr/local/fsbackup/sys_backup"


#-------------------
# Full path of postgresql programs.
# Путь к программам postgresql
#-------------------

backup_progdump_path="/usr/local/pgsql/bin"
#backup_progdump_path="/usr/bin"

#-------------------
# Extra flags for pg_dump program.
# -D - Dump data as INSERT commands with  explicit  column names
# Дополнительные параметры для pg_dump
# -D - формировать бэкап данных в виде INSERT комманд, с указанием названий
#      столбцов. Если скорость восстановления из бэкапа и размер бэкапа
#      более важны, и совместимостью с другими СУБД можно пренебречь,
#      используйте: extra_pg_dump_flag=""
#      Новое имя '-D' опции: --inserts
#
#  -h, --host=ИМЯ           имя сервера баз данных или каталог сокетов
#  -l, --database=ИМЯ_БД    выбор другой базы данных по умолчанию
#  -p, --port=ПОРТ          номер порта сервера БД
#  -U, --username=ИМЯ       имя пользователя баз данных
#  -w, --no-password        не запрашивать пароль
#  -W, --password           запрашивать пароль всегда (обычно не требуется)
#-------------------

extra_pg_dump_flag="--inserts"
#extra_pg_dump_flag=""

############################################################################

if [ "_$backup_sqluser" != "_" ]; then
	# заполняем $PGPASS_FILE для авторизации
	echo "$backup_sqlhost:$backup_sqlport:*:$backup_sqluser:$backup_sqlpassword" > $PGPASS_FILE
	chmod 0600 $PGPASS_FILE

	# добавляем авторизацию в параметры
	extra_pg_dump_flag="$extra_pg_dump_flag -U $backup_sqluser"
	if [ "_$backup_sqlhost" != "_" ]; then
		extra_pg_dump_flag="$extra_pg_dump_flag -h $backup_sqlhost"
	fi
	if [ "_$backup_sqlport" != "_" ]; then
		extra_pg_dump_flag="$extra_pg_dump_flag -p $backup_sqlport"
	fi
fi

if [ "_$backup_suuser" != "_" ] && [ $chown_by_suuser -eq 1 ]; then
    chown -R $backup_suuser $backup_path
    chown $backup_suuser $PGPASS_FILE
fi

if [ -n "$backup_progdump_path" ]; then
    backup_progdump_path="$backup_progdump_path/"
fi

#------------------------

if [ $wal_backup -eq 1 ]; then
    echo "Creating last daily backup before new full backup"
    /usr/local/fsbackup/scripts/daily_pgsql_backup.sh "force"
fi

#-------------------------------------------------------------------------
# Полный бэкап для Postgresql
if [ "_$backup_method" = "_full" ]; then
    echo "Creating full backup of all PostgreSQL databases."
    if [ "_$backup_sqluser" = "_" ]; then
        ${backup_progdump_path}pg_dumpall $extra_pg_dump_flag -s > $backup_path/$backup_name-struct-pgsql
    fi
    if [ "_$backup_suuser" != "_" ]; then
        su - ${backup_suuser} -c ${backup_progdump_path}/pg_dumpall $extra_pg_dump_flag > $backup_path/$backup_name-pgsql
    else
        ${backup_progdump_path}/pg_dumpall $extra_pg_dump_flag > $backup_path/$backup_name-pgsql
    fi

#-------------------------------------------------------------------------
# Бэкап указанных баз для Postgresql
elif [ "_$backup_method" = "_db" ]; then
    echo "Creating full backup of $backup_db_list PostgreSQL databases."
    if [ "_$backup_sqluser" = "_" ]; then
        ${backup_progdump_path}pg_dumpall $extra_pg_dump_flag -s > $backup_path/$backup_name-struct-pgsql
    fi
    cat /dev/null > $backup_path/$backup_name-pgsql

    for cur_db in $backup_db_list; do
	echo "Dumping $cur_db..."
	cur_db=`echo "$cur_db" | awk -F':' '{if (\$2 != ""){print "-t", \$2, \$1}else{print \$1}}'`
	if [ "_$backup_suuser" != "_" ]; then
		chown $backup_suuser $backup_path/$backup_name-pgsql
		su - ${backup_suuser} -c ${backup_progdump_path}pg_dump $extra_pg_dump_flag $cur_db >> $backup_path/$backup_name-pgsql
        else
		${backup_progdump_path}pg_dump $extra_pg_dump_flag $cur_db >> $backup_path/$backup_name-pgsql
	fi
    done
    gzip -f $backup_path/$backup_name-pgsql

#-------------------------------------------------------------------------
# Бэкап всех баз кроме указанных для Postgresql
elif [ "_$backup_method" = "_notdb" ]; then
    echo "Creating full backup of all PostgreSQL databases except databases $backup_db_list."
    if [ "_$backup_suuser" != "_" ]; then
        # TODO: нужно доделать это место ниже... а пока заглушка:
        echo "The '$backup_method' method does not support the 'backup_suuser' parameter, yet. Sorry, exit..."
        exit 1
    fi
    if [ "_$backup_sqluser" = "_" ]; then
        ${backup_progdump_path}pg_dumpall $extra_pg_dump_flag -s > $backup_path/$backup_name-struct-pgsql
    fi
    cat /dev/null > $backup_path/$backup_name-pgsql

    for cur_db in `${backup_progdump_path}psql -A -q -t -c "select datname from pg_database" template1 | grep -v '^template[01]$' `; do

	grep_flag=`echo " $backup_db_list"| grep " $cur_db:"`
	if [ -n "$grep_flag" ]; then
# Исключение таблиц для данной базы
	    for cur_db_table in `${backup_progdump_path}psql -A -q -t -c "select tablename from pg_tables WHERE tablename NOT LIKE 'pg\_%' AND tablename NOT LIKE 'sql\_%';" $cur_db`; do

		flag=1
		for cur_ignore in $backup_db_list; do
		    if [ "_$cur_ignore" = "_$cur_db:$cur_db_table" ]; then
			flag=0
		    fi
		done

		if [ $flag -gt 0 ]; then
		    echo "Dumping $cur_db:$cur_db_table..."
		    ${backup_progdump_path}pg_dump $extra_pg_dump_flag -t $cur_db_table $cur_db >> $backup_path/$backup_name-pgsql
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
		${backup_progdump_path}pg_dump $extra_pg_dump_flag $cur_db >> $backup_path/$backup_name-pgsql
	    else
		echo "Skiping $cur_db..."
	    fi
	fi
    done
    gzip -f $backup_path/$backup_name-pgsql
else
    # Unknown $backup_method
    echo "Configuration error. Not valid parameters in backup_method."
    exit 1
fi

if [ $wal_backup -eq 1 ]; then
    # rotate daily backups (prepare for new WAL files)
    /usr/local/fsbackup/scripts/daily_pgsql_rotate.pl "do"
fi

