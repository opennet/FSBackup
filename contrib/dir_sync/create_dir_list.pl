#!/usr/bin/perl
# Скрипт для построения полного списка поддиректорий и симлинков для заданной директории.
# (c) Maxim Chirkov <mc@tyumen.ru>
#
# Формат использования: create_dir_list.pl /dir > list.txt

use strict;
use File::Find;
my $cfg_exclude_mask='\/backup\/.*';
my %uid_hash=();
my %gid_hash=();

if (defined $ARGV[0] && -d $ARGV[0]){
    find(\&process_dirs, $ARGV[0]);
    exit;
} else {
    die "Usage: create_dir_list.pl <dir>";
}

exit;


sub process_dirs{
    my $file_name = $_;
    my $full_path = $File::Find::name;
    my $full_dir = $File::Find::dir;

    if ( (-d $full_path || -l $full_path ) && $file_name !~ /^\.\.?$/ && $full_path !~ /^$cfg_exclude_mask$/){
	my (undef, undef, $stat_mode, undef, $stat_uid, $stat_gid, undef, undef, undef, $stat_mtime, $stat_time) = stat($full_path);
        # $stat_mode = sprintf ("%04o", $stat_mode & 07777);
	if (! defined $uid_hash{$stat_uid}){
	    $uid_hash{$stat_uid} = getpwuid($stat_uid) || $stat_uid;
	}
	if (! defined $gid_hash{$stat_gid}){
	    $gid_hash{$stat_gid} = getgrgid($stat_gid) || $stat_gid;
	}

	if (-d $full_path){
	    print "dir\t$full_path\t$stat_mode\t$uid_hash{$stat_uid}\t$gid_hash{$stat_gid}\t$stat_mtime\t$stat_time\t\n";
	} elsif (-l $full_path){
	    my $link_dest = readlink($full_path);
	    print "symlink\t$full_path\t$stat_mode\t$uid_hash{$stat_uid}\t$uid_hash{$stat_gid}\t$stat_mtime\t$stat_time\t$link_dest\n";
	}
    }
    return 0;
}
