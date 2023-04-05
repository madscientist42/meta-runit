# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the services sets we provide for this to be a runit based package set...
# (Perversely, there's no config, no init provided in the base recipe, so
# we're going to graciously provide them here...)
SRC_URI += " \
    file://sv/ptpd/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"
RUNIT_DEFAULT_MODS = "log"

