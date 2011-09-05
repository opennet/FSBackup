#!/usr/bin/perl
#
# Created by Molchanov Alexander <xorader@mail.ru> 2010
# ver: 0.2
#
# Делает ротацию WAL (Write-Ahead Logs) на FTP backup сервере в папку $cfg_remote_path/OLD
# Это нужно сделать сразу после полного бакапа PG SQL
# Этот скрипт вызывается автоматически из pgsql_backup.sh

use strict;

use POSIX;
use Net::FTP;
use DB_File;

my $ftp;
my $cur_dir;

my $cfg_remote_host = "fsbackupserver.company.net";
my $cfg_remote_login = "fsbackup";
my $cfg_remote_path = "/hostname_pgsql_daily";
my $cfg_remote_ftp_mode = 1;
my $cfg_remote_password = "xxxxxxxxxxx";
#######

# protect from Lmaos

if ($ARGV[0] ne "do")
{
	printf "Usage: daily_pgsql_rotate.pl do\n";
    printf "Do not run this script by hand if not sure."
	exit 0;
}

#

$ftp = Net::FTP->new($cfg_remote_host, Timeout => 30, Debug => 0,  Passive => $cfg_remote_ftp_mode) || die "Can't connect to ftp server.\n";
$ftp->login($cfg_remote_login, $cfg_remote_password) || die "Can't login to ftp server.\n";
$ftp->binary();

$ftp->cwd($cfg_remote_path) || die "Path $cfg_remote_path not found on ftp server.\n";

# delete/create OLD dir
$ftp->mkdir("$cfg_remote_path/OLD");
$ftp->cwd("$cfg_remote_path/OLD");
foreach $cur_dir ($ftp->ls()){
	$ftp->delete($cur_dir);
}

# move old files to "OLD" dir
$ftp->cwd("$cfg_remote_path");
foreach $cur_dir ($ftp->ls()){
	if ($cur_dir !~ /OLD/){
		#printf "$cur_dir\n";
		$ftp->rename($cur_dir,"OLD/$cur_dir");
	}
}
# for control delete
$ftp->cwd("$cfg_remote_path");
foreach $cur_dir ($ftp->ls()){
	if ($cur_dir !~ /OLD/){
		$ftp->delete($cur_dir);
	}
}

$ftp->quit;



