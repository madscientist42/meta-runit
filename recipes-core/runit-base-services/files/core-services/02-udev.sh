# vim: set ts=4 sw=4 et:

. /etc/runit/functions

[ -n "$VIRTUALIZATION" ] && return 0

msg "Starting udev and waiting for devices to settle..."

# Presume the fstab has a /run tmpfs mount for us to work with- we're
# early enough we want to just do this...
mount /run

mkdir -p /run/udev
udevd --daemon
udevadm trigger --action=add --type=subsystems
udevadm trigger --action=add --type=devices
udevadm settle

