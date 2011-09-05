#!/bin/sh
# Script for reinstall packages stored by sysbackup.sh
# Скрипт для восстановления пакетов с программами.
# 
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>

#-------------------
# Name of backup, single word.
# Имя бэкапа.
#-------------------

backup_name="test_host"


#-------------------
# Directory with installed packets list, stored by sysbackup.sh.
# Директория где расположен сохраненный скриптом sysbackup.sh список пакетов.
#-------------------

sysbackup_path="/usr/local/fsbackup/sys_backup" 


#-------------------
# Directory where stored OS packages.
# Директория где располдожены файлы с пакетами программ.
# Для FreeBSD, если переменная не заполнена, пакеты будут установленны с сайта 
# производителя.
#-------------------

packages_path="/usr/local/INST/RPMS" 


############################################################################
sysname="`uname | tr '[A-Z]' '[a-z]'`"
echo "OS: $sysname"

if [ "_$sysname" = "_linux" ]; then
    for cur_pkg in `cat $sysbackup_path/${backup_name}-pgk.list`; do
        echo "Installing $cur_pkg from local server..."
	rpm -i --nodeps $packages_path/$cur_pkg.*.rpm
    done
fi

if [ "_$sysname" = "_freebsd" ]; then
    if [ -z "$packages_path" ]; then
	for cur_pkg in `cat $sysbackup_path/${backup_name}-pgk.list |sed 's/^\(.*\)\-[0987654321.]*.*$/\1/'|sort|uniq`; do
	    echo "Installing $cur_pkg from remote server..."
    	    pkg_add -r $cur_pkg	
	done
    else
	export PKG_PATH=$packages_path
	for cur_pkg in `cat $sysbackup_path/${backup_name}-pgk.list`; do
        echo "Installing $cur_pkg from local path $packages_path..."
	    if -f $cur_pkg; then 
	        pkg_add $cur_pkg
	    else
		echo "Package $cur_pkg not found, tying to install by mask..."
		cur_pkg= `echo $cur_pkg| sed 's/^\(.*\)\-[0987654321.]*.*$/\1/'`
		pkg_add ${cur_pkg}-*.tgz
	    fi
	done
    fi
fi




