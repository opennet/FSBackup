#!/usr/bin/perl
# Скрипт создающий недастоющие директории и симлинки в пункте назначения по общему списку.
# Список директорий подается во входной поток.
# (c) Maxim Chirkov <mc@tyumen.ru>
#
# Формат использования: cat list.txt |./restore_dir.pl /корень_для_восстановления

use strict;

my %uid_hash=();
my %gid_hash=();

if (! defined $ARGV[0] || ! -d $ARGV[0]){
    die "Usage: restore_dir.pl <dir>";
}
my $root_path = $ARGV[0];

while (<STDIN>){
    chomp;
    my ($s_type, $s_path, $s_mode, $s_uid, $s_gid, $s_mtime, $s_time, $s_link_dest) = split(/\t/);
    my $stat_mode = sprintf ("%04o", $s_mode & 07777);
    
    if ($s_path !~ /^\Q$root_path\E/){
	print "ERROR: Outside dir: $s_path\n";
	next;
    }
    if (-e $s_path){next;}
    
    if (! defined $uid_hash{$s_uid}){
        $uid_hash{$s_uid} = getpwnam($s_uid) || $s_uid;
    }
    if (! defined $gid_hash{$s_gid}){
        $gid_hash{$s_gid} = getgrnam($s_gid) || $s_gid;
    }

    if ($s_type eq "dir"){

	mkdir($s_path, 0777);
	chmod(oct($stat_mode), $s_path);
	chown ($uid_hash{$s_uid}, $gid_hash{$s_gid}, $s_path);
	utime ($s_mtime, $s_mtime, $s_path);
	print "Restoring dir: $s_path\n";

    } elsif ($s_type eq "symlink"){

	symlink($s_link_dest, $s_path);
	print "Restoring symlink: $s_path\n";

    } elsif ($s_type ne ""){
	print "ERROR: Bogus line: $_\n";
    }
}
