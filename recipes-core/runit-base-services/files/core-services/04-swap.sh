# vim: set ts=4 sw=4 et:

. /etc/runit/functions

[ -n "$VIRTUALIZATION" ] && return 0

msg "Initializing swap..."
swapon -a || emergency_shell
