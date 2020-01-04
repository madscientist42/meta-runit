# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Make it a runit capable recipe...
inherit runit

# Add to the SRC_URI for our runit, etc. piece parts...
SRC_URI += " \
    file://sv/avahi-demon/run \
    "

# Specify that this service needs to be ran
RUNIT-SERVICES = "DEFAULT"

# Add any of our run entries to the respective package sets...
FILES_avahi-daemon += " \
    /etc/sv \
    /etc/runit \
    "