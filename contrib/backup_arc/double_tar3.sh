#!/bin/sh

# Копирование /home/backup_* с бэкапами на запасной диск и тройная ротация на 3 диска.
# Удаление на запасной диске "OLD" директорий.
# 8 23 5,20 * * /usr/local/etc/backup/double_tar3.sh

reserv0="/backup/reserv.0"
reserv1="/backup2/backup_reserv/reserv.1"
reserv2="/backup3/reserv.2"


rm -rf $reserv2
mv -f $reserv1 $reserv2
mv -f $reserv0 $reserv1

mkdir $reserv0
cp -Rfp /home/backup_* $reserv0
find $reserv0 -name OLD -type d -exec rm -rf {} \;

