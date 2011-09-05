#!/bin/sh

# Пример простейшего скрипта для закачки архива на FTP средствами curl
# Используется при невозможности установить на машину Perl (например, рутер на Flash).

hour=`date +%H`
ftp_host=192.168.1.1
ftp_auth="логин:пароль"
ftp_backup_store_path="/var/backups"

backup_dirs="/etc /usr/local/fsbackup"
backup_name="backup_router1"

tar czf - $backup_dirs | curl --upload-file - --user $ftp_auth ftp://$ftp_host/$ftp_backup_path/$backup_name-$hour.tar.gz
