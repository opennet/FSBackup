#!/bin/sh
# Зеркалирование /home в /backup2
# 8 18 * * * /usr/local/etc/backup/double_mirror.sh >/var/log/rsync.log 

date
/usr/local/bin/rsync -a -v --delete --delete-excluded --backup --exclude-from=/usr/local/etc/rsync_backup.exclude / /backup2/rsync 

RETCODE=$?
if [ $RETCODE -ne 0 -a $RETCODE -ne 24 ]; then
        echo "Err code=$RETCODE"| mail -s "FATAL RSYNC BACKUP" admins@test.ru
fi
echo RET: $RETCODE
date
