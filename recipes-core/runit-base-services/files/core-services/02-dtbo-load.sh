#!/bin/sh

. /etc/runit/functions

# NOTE: This is currently the "correct" path for things and the
# behaviors in this directory is 1-for-1 the same whether you're
# talking the Xilinx patches, 6.x behaviors, or dtbocfg out of tree
# module.
CONFIGFS_DIR="/sys/kernel/config/device-tree/overlays"

# Check to see if we have CONFIGS_DIR present.  If not, we're going
# to check and see if we can/need to load dtbocfg since we DO offer
# this support for people if they're not in one of the other places.
if [ ! -e $CONFIGFS_DIR ] ; then
    find /lib/modules | grep -q dtbocfg
    if [ $? -eq 0 ]; then
        # Attempt modprobing the module...
        modprobe dtbocfg
    fi
fi

# Now, check to see if we've got the CONFIGS_DIR and /etc/dtbos present...
# If so, proceed to attempt to load DTBOs into the DT data store.
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
            # Check to see if we're using a Xilinx version of things or not.
            if [ ! -e $dtbo_name/path ] ; then
                # Nope.  Use the normal method which is to load the DTBO into
                # the sysfs edge via a cp call into it.
                cp $dtbo $dtbo_name/dtbo
            else
                # Xilinx.  Set the path instead.
                echo $dtbo > $dtbo_name/path
            fi
            echo 1 > $dtbo_name/status
        done

        msg_done "Loaded overlays"
    fi
fi
