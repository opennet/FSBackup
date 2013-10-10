#!/usr/bin/perl
# Script to install fsbackup package and some required perl modules
# --prefix=install path, default /usr/local/fsbackup
# --prefix-man=manual path location, default /usr/local/man/man1
#
# Скрипт для установки программы и всех недостающих Perl модулей.
# --prefix=путь куда устаналивать программу, по умолчанию /usr/local/fsbackup
# --prefix-man=путь куда скопировать системное руководство для программы.
#
# http://www.opennet.ru/dev/fsbackup/
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>

$default_install_path = "/usr/local/fsbackup";
$default_install_man = "/usr/local/man/man1";

#########################################################################
%module_list = (
		"Digest/MD5.pm" 	=> "Digest-MD5-2.13.tar.gz",
		"DB_File.pm"		=> "DB_File-1.77.tar.gz",
		"Net/FTP.pm"		=> "libnet-1.0703.tar.gz",
		);

#-----------------------------------------------------------------------
use Getopt::Long;

GetOptions("prefix=s", \$prefix, "prefix-man=s", \$prefix_man);

$prefix = defined($prefix) ? $prefix : $default_install_path;
$prefix_man = defined($prefix_man) ? $prefix_man : $default_install_man;
print "Installing to $prefix (man to $prefix_man)\n";

chomp($prog_md5sum = `which md5sum`);
chomp($prog_tar = `which tar`);
chomp($prog_ssh = `which ssh`);
chomp($prog_rm = `which rm`);
chomp($prog_gzip = `which gzip`);
chomp($prog_pgp	= `which gpg`);
chomp($prog_sqlite	= `which sqlite`);
$prog_pg_dump = `which pg_dump` || "/usr/local/pgsql/bin/pg_dump";
$prog_pg_dump =~ s/^(.*)\/[^\/]+$/$1/;
chomp($prog_pg_dump);
$prog_mysqldump = `which mysqldump` || "/usr/local/mysql/bin/mysqldump";
$prog_mysqldump =~ s/^(.*)\/[^\/]+$/$1/;
chomp($prog_mysqldump);
chomp($backup_name = `uname -n|tr '.' '_'`);

print "Makeing man page...\n";
system ("pod2man fsbackup.pl > fsbackup.1");
print "Installing man page to $prefix_man...\n";
system ("mkdir -p $prefix_man");
system ("cp -f fsbackup.1 $prefix_man/fsbackup.1");
system ("chmod 644 $prefix_man/fsbackup.1");

print "Creation directory tree in $prefix...\n";

if (! -d $prefix){	
    system ("mkdir $prefix");
    system ("chmod 755 $prefix");
}
system ("mkdir $prefix/cache");
system ("chmod 700 $prefix/cache");
system ("mkdir $prefix/scripts");
system ("chmod 700 $prefix/scripts");
system ("mkdir $prefix/sys_backup");
system ("chmod 700 $prefix/sys_backup");

print "Installing fsbackup in $prefix...\n";

system ("cp -f FAQ $prefix/FAQ");
system ("chmod 644 $prefix/FAQ");
system ("cp -f README $prefix/README");
system ("chmod 644 $prefix/README");
system ("cp -f VERSION $prefix/VERSION");
system ("chmod 644 $prefix/VERSION");
system ("cp -f fsbackup.1 $prefix/fsbackup.1");
system ("chmod 644 $prefix/fsbackup.1");

copyfile("fsbackup.pl", "$prefix/fsbackup.pl");
system ("chmod 711 $prefix/fsbackup.pl");
copyfile("cfg_example", "$prefix/cfg_example");
system ("chmod 600 $prefix/cfg_example");
copyfile("cfg_example_users", "$prefix/cfg_example_users");
system ("chmod 600 $prefix/cfg_example_users");
copyfile("cfg_example_users", "$prefix/cfg_example_sql");
system ("chmod 600 $prefix/cfg_example_sql");
copyfile("create_backup.sh", "$prefix/create_backup.sh");
system ("chmod 711 $prefix/create_backup.sh");
copyfile("scripts/mysql_backup.sh", "$prefix/scripts/mysql_backup.sh");
system ("chmod 711 $prefix/scripts/mysql_backup.sh");
copyfile("scripts/sysbackup.sh", "$prefix/scripts/sysbackup.sh");
system ("chmod 711 $prefix/scripts/sysbackup.sh");
copyfile("scripts/fsrestore.sh", "$prefix/scripts/fsrestore.sh");
system ("chmod 711 $prefix/scripts/fsrestore.sh");
copyfile("scripts/pgsql_backup.sh", "$prefix/scripts/pgsql_backup.sh");
system ("chmod 711 $prefix/scripts/pgsql_backup.sh");
copyfile("scripts/sysrestore.sh", "$prefix/scripts/sysrestore.sh");
system ("chmod 711 $prefix/scripts/sysrestore.sh");
copyfile("scripts/sqlite_backup.sh", "$prefix/scripts/sqlite_backup.sh");
system ("chmod 711 $prefix/scripts/sqlite_backup.sh");
copyfile("scripts/mount-windows-share.sh", "$prefix/scripts/mount-windows-share.sh");
system ("chmod 711 $prefix/scripts/mount-windows-share.sh");

print "* If you system not support MD5, please manually install module ./modules/Digest-Perl-MD5-1.5.tar.gz\n";
print "* If Berkeley DB not installed and failed compilation of DB_File-1.77.tar.gz, please manually install DB from http://www.sleepycat.com.\n";

while (($cur_module_path, $cur_archive)= each(%module_list)) {
    
    $cur_module = $cur_module_path;
    $cur_module =~ s/\//::/g;
    print "Checking for module $cur_module...\n";
    $installed_flag = 0;
    foreach $prefix (@INC) {
	if (-f "$prefix/$cur_module_path") {
	    $installed_flag = 1;
	    last;
	}
    }
    if ($installed_flag == 1){
	print "Module $cur_module already installed, skiping installation procedure.\n";
    } else {
	install_module($cur_module, $cur_archive);
    }
    print "\n";
}


print "Installation complete.\n";
exit;
#############################################################
# Процедура для копирования файлов с изменениями

sub copyfile{
	my ($from_file, $to_file) = @_;

    open(FROM_FILE, "<$from_file")||die "Can't open $from_file\n";
    flock(FROM_FILE, 1);
    open(TO_FILE, ">$to_file")||die "Can't create $to_file\n";
    flock(TO_FILE, 2);
    while(<FROM_FILE>){    
	$line = $_;
	if ($prog_md5sum ne "" && $prog_md5sum !~ /\s/){
	    $line =~ s/"md5sum -b"/"$prog_md5sum -b"/;
	}
	if ($prog_tar ne "" && $prog_tar !~ /\s/){
	    $line =~ s/"tar"/"$prog_tar"/;
	}
	if ($prog_ssh ne "" && $prog_ssh !~ /\s/){
	    $line =~ s/"ssh"/"$prog_ssh"/;
	}
	if ($prog_rm ne "" && $prog_rm !~ /\s/){
    	    $line =~ s/"rm"/"$prog_rm"/;
	}
	if ($prog_gzip ne "" && $prog_gzip !~ /\s/){
	    $line =~ s/"gzip"/"$prog_gzip"/;
	}
	if ($prog_pgp ne "" && $prog_pgp !~ /\s/){
	    $line =~ s/"gpg"/"$prog_pgp"/;
	}
	if ($prog_pg_dump ne "" && $prog_pg_dump !~ /\s/){
	    $line =~ s/"\/usr\/local\/pgsql\/bin"/"$prog_pg_dump"/;
	}
	if ($prog_mysqldump ne "" && $prog_mysqldump !~ /\s/){
	    $line =~ s/"\/usr\/local\/mysql\/bin"/"$prog_mysqldump"/;
	}
	if ($backup_name ne ""){
	    $line =~ s/"test_host"/"$backup_name"/;
	}
    
	if ($prefix ne "/usr/local/fsbackup"){
	    $line =~ s/\/usr\/local\/fsbackup/$prefix/;
	}
	print TO_FILE $line;
    }
    close(TO_FILE);
    close(FROM_FILE);
}
######################################################################
# Процедура для автоматической установки модулей.
sub install_module{
	my($module_name, $module_archive) = @_;
	my ($module_dir);

    $module_archive =~ /^(.+)\.tar\.gz$/;
    $module_dir = $1;
    print "Unpcking archive $module_archive..\n";
    print "Installing module $module_name..\n";
    system ("tar -xzf ./modules/$module_archive -C ./modules/");
    chdir ("./modules/$module_dir");
    system "perl Makefile.PL; make; make install";
    print "Installation of module $module_name successfully complete.\n";
    chdir ("../../");
}
