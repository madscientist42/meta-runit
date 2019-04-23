#!/bin/sh
. /etc/runit/functions

# Go check for any of the package management backend postinst hooks...
backend_list="rpm deb ipk"
do_postinsts=0
for pm in $backend_list; do
    if [ -e /etc/$pm-postinsts ] ; then
        do_postinsts=1
    fi
done

if [ "$do_postinsts" == "1" ] ; then
    # Found a first-boot set of config items...
    msg "Runnning first-boot configuration for installed packages\n"
    msg "(This may take a few moments...)\n"
    /usr/sbin/run-postinsts 
fi
