# vim: set ts=4 sw=4 et:

[ -n "$VIRTUALIZATION" ] && return 0

# See if we're provisioned for a choke off for non-network 
# mount failures or if we just warn...
[ -e /etc/default/mount ] && . /etc/default/mount 

. /etc/runit/functions

msg "Remounting rootfs read-only..."
mount -o remount,ro / || emergency_shell

if [ -x /bin/btrfs ]; then
    msg "Activating btrfs devices..."
    btrfs device scan || emergency_shell
fi

[ -f /fastboot ] && FASTBOOT=1
[ -f /forcefsck ] && FORCEFSCK="-f"
for arg in $(cat /proc/cmdline); do
    case $arg in
        fastboot) FASTBOOT=1;;
        forcefsck) FORCEFSCK="-f";;
    esac
done

if [ -z "$FASTBOOT" ]; then
    msg "Checking filesystems:"
    fsck -A -T -a -t noopts=_netdev $FORCEFSCK
    if [ $? -gt 1 ]; then
        emergency_shell
    fi
fi

msg "Mounting rootfs read-write..."
mount -o remount,rw / || emergency_shell

msg "Mounting all non-network filesystems..."
# We're going to do this in a small millisleep loop and then if 
# it chokes after several times, we'll warn people that it's 
# happened...  If the install is configured to go to an emergency
# shell session with this failure (Some systems can fail at this
# point and properly boot, etc.) we go there.
err="1"
counter=0
while [ "$err" == "1" -a $counter -lt 10 ]; do
    # mount -a and see if we mount.  If it chokes we want to see 
    # the fail on the console/console-log...
    mount -a -t "nosysfs,nonfs,nonfs4,nosmbfs,nocifs" -O no_netdev 
    if [ $? -eq 0 ]; then 
        err="0"
    else 
        counter=$(( $counter + 1 ))

        # Doze for 200 msec...
        millisleep 200
    fi 
done
if [ "$err" == "1" ] ; then 
    msg_err "Mount of non-network filesystems FAILED!"
    [ $MOUNT_EMERG_SHELL -eq 1 ] && emergency_shell
fi
