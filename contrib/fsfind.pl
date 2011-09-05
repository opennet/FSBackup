#!/usr/bin/perl

# Скрипт для поиска файлов в архивах созданных программой fsbackup             
# Copyright (c) 2001 by Alex Sokoloff. <sokoloff@mail.ru>   
#                                                           
# Написан для fsbackup                                      
# http://www.opennet.ru/dev/fsbackup/                       
# Copyright (c) 2001 by Maxim Chirkov. <mc@tyumen.ru>       

#############################################

my $type="list";
my $extract=0;
$cfg_cache_dir = "./";
my $findfile;

# Обработка параметров командной строки
while (@ARGV){
    $arg= shift (@ARGV);
    if 	  ($arg eq "-h" or $arg eq "--help") {&help}		
    elsif ($arg eq "-d" or $arg eq "--del")  { $type="del"}	
    elsif ($arg eq "-c" or $arg eq "--cfgfile")  {
	    $config = shift (@ARGV);
	    require "$config" if ( -f $config );
    	}
    elsif ($arg eq "-p" or $arg eq "--path")  {
	$cfg_cache_dir=shift (@ARGV);
	}
    elsif ($arg eq "-m" or $arg eq "--mask")  {	
	$cfg_backup_name = shift (@ARGV);
	}
    else {$findfile="$arg"}
}

if ($findfile eq '') {
    print "Не указан искомый файл\n";
    &help;
}

if ( ! -d $cfg_cache_dir ) {print "Дирректория: $cfg_cache_dir не найдена\n"; &help}

@files=sort {$b cmp $a} glob("$cfg_cache_dir/$cfg_backup_name*.$type" );
if ($#files <0) {
    print "В дирректории $cfg_cache_dir не найден ни один файл $cfg_backup_name.$type\n";
    exit;    
}

# Переводим регулярные выражения 
$findfile=~ s/\./\\\./g;
$findfile=~ s/\*/\.\+/g;    
$findfile=~ s/\_/\./g;        

# Собственно поиск и печать результатов    
foreach $f (@files){
    open (FILE, "$f");
    $tmp ="$f\n";

    while (<FILE>){
	chomp;
	if (/$findfile/i){ $tmp.="\t$_\n";}
    }
    
    if ($tmp ne "$f\n" ){ 
	$tmp=~ s/^$cfg_cache_dir\///;
    	print "$tmp\n"; 
    }		
}

exit;

sub help{
print qq|Usage: fsfind  [OPTION]...  FILE
Ищет FILE в архивах созданных в fsbackup, В имени файла допускается
использование регулярных выражений:
  *   любое количество любых символов
  _   любой одиночный символ

Опции:
  -d, --del	      	искать удаленные файлы
  -p, --path ПУТЬ	путь к дирректории с архивами, если не указано,
                         то поиск ведется в текущей дирректории
  -m, --mask            Маска для имен файлов архивов в которых производится 
                         поиск
  -c, --cfgfile ФАЙЛ    файл конфигурации fsbackup в котором прописана 
			 дирректория с архивами и имя файла архива
  -h, --help	    	вывести эту подсказку и выйти

|;
    exit;                                                                     
}

