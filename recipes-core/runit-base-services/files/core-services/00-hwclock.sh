#!/bin/sh

# Presume we're just pulling from the RTC...  IF we have the app...
[ ! -x /sbin/hwclock ] && exit 0

. /etc/runit/functions

[ -f /etc/default/hwclock ] && . /etc/default/hwclock

if [ "$VERBOSE" != no ] ; then
        msg "System time was `date`."
        msg "Setting the System Clock using the Hardware Clock as reference..."
fi

if [ "$HWCLOCKACCESS" != no ] ; then
    if [ -z "$TZ" ] ; then
        hwclock $tz --hctosys
    else
        TZ="$TZ" hwclock $tz --hctosys
    fi
fi

if [ "$VERBOSE" != no ] ; then
    msg "System Clock set. System local time is now `date`."
fi


