# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# This is an annex of the original metadata.  So, if you modify this file, bump
# the number in this .bbappend to reflect the change and force a re-build.
PR =. "+runit-r1"

# Make it a runit capable recipe...
inherit runit

# Add to the SRC_URI for our runit, etc. piece parts...
SRC_URI += " \
    file://sv/avahi-daemon/run \
    "

# Specify that this service needs to be ran
RUNIT-SERVICES = "DEFAULT"
RUNIT_DEFAULT_MODS = "log"

# Add any of our run entries to the respective package sets...
FILES:avahi-daemon += " \
    /etc/sv \
    /etc/runit \
    "