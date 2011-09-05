#!/bin/bash

backup_path="/usr/local/fsbackup"
config_file="cfg_home"

[ $# -ne 1 ] &&  [ $# -ne 2 ] && {
	echo "Usage: $0 <backuped path> [path to store]"
	exit 1
}

restore_path=$1
[ $# -eq 2 ] && rdir=$2 || rdir='/'


[ "${restore_path:0:1}" != "/" ] && {
	echo "Absolute path required"
	exit 1
}

[ "${rdir:0:1}" != "/" ] && {
	echo "Absolute path required"
	exit 1
}

restore_path=`echo $restore_path | sed 's/\/$//'`
rdir=`echo $rdir | sed 's/\/$//'`

[ -f $rdir ] && {
	echo "Can't store to file, directory needed"
	exit 1
}

function getvar() (
	[ $# -ne 1 ] && return ''
	str=$1
	grep $str $config_file | sed 's/^[^\"][^\"]*\"\([^\"][^\"]*\)\".*$/\1/' | head -n 1
)

function makedirs() (
	[ $# -ne 2 ] && return 1
	dir=$1
	arch=$2
	[ "${dir:0:1}" != . ] && return 1
	[ "$dir" = "." ] && return 0
	makedirs `dirname $dir` $arch
	[ $? -eq 1 ] && return 1
	ssh $cfg_remote_login@$cfg_remote_host grep "\'$dir\'" $arch | sh
	[ $? -ne 0 ] && return 1
	return 0
)

function ssh_restore() {
	[ $# -ne 1 ] && return 1
	n=$1
	i=0
	for date in $dates
	do
		i=$[$i+1]
		[ $i -eq $n ] && arch=$cfg_remote_path/$cfg_backup_name-$date
	done
	arch_list=`ssh $cfg_remote_login@$cfg_remote_host grep -l .$restore_path $arch*\.tlist`
	isdir=`ssh $cfg_remote_login@$cfg_remote_host grep \'\.$restore_path\' $arch.dir`
	[ -d $rdir ] || mkdir -p -m 755 $rdir
	cd $rdir
	[ -z "$isdir" ] && (
		archgz=`echo $arch_list | sed 's/tlist$/tar.gz/'`
		makedirs .`dirname $restore_path` $arch.dir
		ssh $cfg_remote_login@$cfg_remote_host tar -C $cfg_remote_path/restore -xzf $archgz .$restore_path
	#	scp $cfg_remote_login@$cfg_remote_host:$cfg_remote_path/restore/$restore_path $rdir$restore_path
		ssh $cfg_remote_login@$cfg_remote_host tar -C $cfg_remote_path/restore`dirname $restore_path` -cf - . | tar -C $rdir`dirname $restore_path` -xf -
		return 0
	) || (
		makedirs .$restore_path $arch.dir
		ssh $cfg_remote_login@$cfg_remote_host grep "\'\.$restore_path" $arch.dir | sh
		for arch in $arch_list
		do
			arch=`echo $arch | sed 's/tlist$/tar.gz/'`
			ssh $cfg_remote_login@$cfg_remote_host tar -C $cfg_remote_path/restore -xzf $arch .$restore_path

		done
		ssh $cfg_remote_login@$cfg_remote_host tar -C $cfg_remote_path/restore$restore_path -cf - . | tar -C $rdir$restore_path -xf -
		return 0
	)
}

cd $backup_path
cfg_type=`getvar cfg_type`

[ "$cfg_type" = "remote_ssh" ] && (
	cfg_remote_host=`getvar cfg_remote_host`
	cfg_remote_login=`getvar cfg_remote_login`
	cfg_remote_path=`getvar cfg_remote_path`

	arch_list=`ssh $cfg_remote_login@$cfg_remote_host grep -l "^.$restore_path$" $cfg_remote_path/*\.list | sort`
	[ -z "$arch_list" ] && arch_list=`ssh $cfg_remote_login@$cfg_remote_host grep -l "^\.$restore_path/" $cfg_remote_path/*\.list | sort`
	[ -z "$arch_list" ] && {
		echo "Not found"
		exit 0
	}
	cfg_backup_name=`getvar cfg_backup_name`
	i=0
	for arch in $arch_list
	do
		i=$[$i+1]
		date=`echo $arch | sed "s#^$cfg_remote_path/$cfg_backup_name-##" | sed 's/\.list$//'`
		dates="$dates $date"
		echo "$i) $date"
	done
	i=$[$i+1]
	echo "$i) All in order by date"
	n=0
	while [ $n -eq 0 ]
	do
		read n
		[ $n -gt $i ] || [ $n -lt 1 ] && {
			echo "Wrong number"
			n=0
		}
	done
	[ $n -eq $i ] && {
		j=1
		i=$[$i-1]
		while [ $j -le $i ]
		do
			ssh_restore $j
			j=$[$j+1]
		done
		exit 0
	}
	ssh_restore $n
)

