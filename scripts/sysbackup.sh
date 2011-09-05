#!/bin/sh
# Script for store system configuration files and information about installed
# packages.
# Скрипт для сохранения списк всех файлов в системе, списка установленных пакетов
# и файлов конфигурации.
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>

#-------------------
# Name of backup, single word.
# Имя бэкапа.
#-------------------

backup_name="test_host"


#-------------------
# Directory to store system backup. 
# Корневая директория куда будут помещены данные системного бэкапа.
#-------------------

sysbackup_path="/usr/local/fsbackup/sys_backup" 


############################################################################
sysname="`uname | tr '[A-Z]' '[a-z]'`"
echo "OS: $sysname"

# echo "Creating ls-lR..."
# ls -lR / |gzip > $sysbackup_path/${backup_name}-ls-lR.gz

if [ "_$sysname" = "_linux" ]; then
    echo "Creating system config archive..."
    rm -f $sysbackup_path/${backup_name}-rpm_conf.tar
    for cur_conf in `rpm -q -a -c`; do
	tar -rf $sysbackup_path/${backup_name}-rpm_conf.tar $cur_conf 2>/dev/null
    done
    echo "Creating package list..."
    gzip -f $sysbackup_path/${backup_name}-rpm_conf.tar
    rpm -q -a > $sysbackup_path/${backup_name}-rpm.list
    #dpkg -l > $sysbackup_path/${backup_name}-deb.list
    cat /proc/partitions > $sysbackup_path/partitions.txt
    cat /proc/mounts > $sysbackup_path/mounts.txt
    cat /proc/modules > $sysbackup_path/modules.txt
    /sbin/fdisk -l > $sysbackup_path/fdisk.txt
    netstat -rn > $sysbackup_path/routes.txt
    # Бэкап MBR
    #dd if=/dev/sda of=$sysbackup_path/mbr_sda.bin bs=1 count=512
    # Списки устройств.
    #cat /proc/pci > $sysbackup_path/pci.txt
    #cat /proc/bus/usb/devices > $sysbackup_path/usb.txt
    #cat /proc/scsi/scsi > $sysbackup_path/scsi.txt
    
fi

if [ "_$sysname" = "_freebsd" ]; then
    echo "Creating package list and install.cfg for sysinstall..."
    sysctl -a > $sysbackup_path/sysctl.txt
    fdisk > $sysbackup_path/fdisk.txt
    geom disk list > $sysbackup_path/geom_disk.txt
    # Выводим данные о таблицах разделов.
    {
	disk_list=`sysctl kern.disks| cut -d':' -f2`
	for disk in $disk_list; do
	    echo "DISK $disk =================="
	    fdisk $disk
    	    fdisk -s $disk |awk -F':' '{if (int($1) > 0){print int($1)}}'| while read slice; do
    		echo "SLICE $slice -----------------"
	        disklabel ${disk}s$slice
	    done                        
        done
    }> $sysbackup_path/disk.txt

    # Сохранение базовой конфигурации			        
    cp -f /etc/rc.conf $sysbackup_path/${backup_name}-rc.conf
    . /etc/rc.conf
    interface=`echo "$network_interfaces"| awk '{print $1}'`;
    eval ifconfig=\$ifconfig_$interface
    ipaddr=`echo "$ifconfig"| sed 's/^.*inet \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*$/\1/'`
    netmask=`echo "$ifconfig"| sed 's/^.*netmask \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*$/\1/'`
    domain_name=`cat /etc/resolv.conf| grep -E "search|domain"| awk '{print $2}'|head -n1`
    nameserver=`cat /etc/resolv.conf| grep 'nameserver'| awk '{print $2}'|head -n1`
    
cat<<ENDL>$sysbackup_path/${backup_name}-install.cfg
# Full example: /usr/src/release/sysinstall/install.cfg
debug=yes
hostname=$hostname
domainname=$domain_name
nameserver=$nameserver
defaultrouter=$defaultrouter
ipaddr=$ipaddr
netmask=$netmask
# ftp=ftp://time.cdrom.com/pub
netDev=$interface
mediaSetFTP
# dists=bin doc manpages info compat21 des src sbase ssys
dists=all
distSetCustom
# File System
## Current /etc/fstab
`cat /etc/fstab|sed 's/^/## /'`
## Exmpale
# disk=ad0
# partition=exclusive
# diskPartitionEditor
# bootManager=booteasy
# diskPartitionEditor
# ad0s1-1=ufs 40960 /
# ad0s1-2=swap 40960 none
# ad0s1-3=ufs 0 /usr 1
# diskLabelEditor
# installCommit
ENDL
    ls -tr /var/db/pkg| tee $sysbackup_path/${backup_name}-pgk.list | perl -ne 'print "package=${_}packageAdd\n"'>> $sysbackup_path/${backup_name}-install.cfg
fi



