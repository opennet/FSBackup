#!/bin/sh
# Ротация почасовых бэкапов SQL за день

# cron:
# 43 0 * * *      /usr/local/fsbackup/scripts/daily_sql_backup.sh >/dev/null

backup_path="/backup/.DB"
backup_path2="/backup/.DB.last"
backup_path3="/backup/.DB.last2"

#/sbin/mount -u -w /backup
#/bin/mount -o remount,rw /backup

rm -rf $backup_path3
mv -f $backup_path2 $backup_path3
mv -f $backup_path $backup_path2
mkdir $backup_path

#sync; sync; sync
#sleep 5
#/sbin/mount -u -r /backup
#/bin/mount -o remount,ro /backup
