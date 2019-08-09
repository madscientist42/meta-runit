# vim: set ts=4 sw=4 et:

. /etc/runit/functions

[ -n "$VIRTUALIZATION" ] && return 0

msg "Starting udev and waiting for devices to settle..."
mkdir -p /run/udev
udevd --daemon
udevadm trigger --action=add --type=subsystems
udevadm trigger --action=add --type=devices
udevadm settle

