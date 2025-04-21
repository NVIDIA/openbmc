#!/bin/sh

findmtd() {
        m=$(grep -xl "$1" /sys/class/mtd/*/name)
        m=${m%/name}
        m=${m##*/}
        echo $m
}


get_fw_env_var() {
	# do we have 1 or 2 copies of the environment?
	# count non-blank non-comment lines
	# copies=$(grep -v ^# /etc/fw_env.config | grep -c [::alnum::])
	# ... we could if we had the fw_env.config in the initramfs
	copies=2

	# * Change \n to \r and \0 to \n
	# * Skip to the 5th byte to skip over crc
	# * then skip to the first or 2nd byte to skip over flag if it exists
	# * stop parsing at first empty line corresponding to the
	#   double \0 at the end of the environment.
	# * print the value of the variable name passed as argument

	envdev=$(findmtd u-boot-env)
	if test -n $envdev
	then
		cat /dev/$envdev |
		tr '\n\000' '\r\n' |
		tail -c +5 | tail -c +${copies-1} |
		sed -ne '/^$/,$d' -e "s/^$1=//p"
	fi
}

optfile=/run/initramfs/init-options
get_fw_env_var openbmconce >> $optfile

if grep -w complete-reset $optfile
then
	echo "Complete reset requested."
	rwfs=$(findmtd rwfs) 
	echo "Erasing read-write partition (/dev/$rwfs)"	
	flash_eraseall /dev/$rwfs
	log=$(findmtd log)
	logdev=/dev/mtdblock${log#mtd}
	echo "Cleaning log directories ($logdev)"	
	mkdir /log-mnt 
	mount -t jffs2 $logdev /log-mnt
	rm -rf /log-mnt/*
	sync
	umount /log-mnt
fi


echo shutdown: "$@"

export PS1=shutdown-sh#\ 
# exec bin/sh

cd /
if [ ! -e /proc/mounts ]
then
	mkdir -p /proc
	mount  proc /proc -tproc
	umount_proc=1
else
	umount_proc=
fi

# Remove an empty oldroot, that means we are not invoked from systemd-shutdown
rmdir /oldroot 2>/dev/null

# Move /oldroot/run to /mnt in case it has the underlying rofs loop mounted.
# Ordered before /oldroot the overlay is unmounted before the loop mount
mkdir -p /mnt
mount --move /oldroot/run /mnt

set -x
for f in $( awk '/oldroot|mnt/ { print $2 }' < /proc/mounts | sort -r )
do
	umount $f
done
set +x

update=/run/initramfs/update
image=/run/initramfs/image-

wdt="-t 1 -T 5"
wdrst="-T 15"

if ls $image* > /dev/null 2>&1
then
	if test -x $update
	then
		if test -c /dev/watchdog
		then
			echo Pinging watchdog ${wdt+with args $wdt}
			watchdog $wdt -F /dev/watchdog &
			wd=$!
		else
			wd=
		fi
		$update --clean-saved-files
		remaining=$(ls $image*)
		if test -n "$remaining"
		then
			echo 1>&2 "Flash update failed to flash these images:"
			echo 1>&2 "$remaining"
		else
			echo "Flash update completed."
		fi

		if test -n "$wd"
		then
			kill -9 $wd
			if test -n "$wdrst"
			then
				echo Resetting watchdog timeouts to $wdrst
				watchdog $wdrst -F /dev/watchdog &
				sleep 1
				# Kill the watchdog daemon, setting a timeout
				# for the remaining shutdown work
				kill -9 $!
			fi
		fi
	else
		echo 1>&2 "Flash update requested but $update program missing!"
	fi
fi

echo Remaining mounts:
cat /proc/mounts

test "$umount_proc" && umount /proc && rmdir /proc

# tcsattr(tty, TIOCDRAIN, mode) to drain tty messages to console
test -t 1 && stty cooked 0<&1

# Execute the command systemd told us to ...
if test -d /oldroot  && test "$1"
then
	if test "$1" = kexec
	then
		$1 -f -e
	else
		$1 -f
	fi
fi


echo "Execute ${1-reboot} -f if all unmounted ok, or exec /init"

export PS1=shutdown-sh#\ 
exec /bin/sh
