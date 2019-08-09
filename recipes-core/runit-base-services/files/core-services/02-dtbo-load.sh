#!/bin/sh

. /etc/runit/functions

CONFIGFS_DIR="/sys/kernel/config/device-tree/overlays"

# Check to see if we've got DTBO load support lit in the kernel...
# (FIXME - Presume that this is driven by dtbocfg as it's the 
#  most readily available out-of-tree without patches.  There's
#  an alternate, "official" one that may be patched in or is 
#  provided with some of the latest kernels that differs slightly 
#  in use.  We'll need to fix this script when we encounter it.)
lsmod | grep -q dtbocfg
if [ $? -eq 0 ] ; then
    # Double check to make sure we have the dtbocfg hook fully
    # in place and we have a directory from to which to install
    # DTBOs from...
    if [ -e $CONFIGFS_DIR -a -e /etc/dtbo ] ; then
        if [ "$(ls -A /etc/dtbo)" ] ; then 
            msg "Installing Device Tree Overlays to the system"

            # Switch to the configfs space we need to drive...
            cd $CONFIGFS_DIR

            # For now, presume that /etc/dtbo holds the overlay configs and
            # we're going to push each and enable, in turn, from that directory.
            for dtbo in /etc/dtbo/* ; do
                dtbo_name=`basename $dtbo`
                mkdir $dtbo_name
                cp $dtbo $dtbo_name/dtbo
                echo 1 > $dtbo_name/status
            done

            msg_done "Loaded overlays"
        fi 
    fi     
fi
