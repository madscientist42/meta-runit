# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# This is an annex of the original metadata.  So, if you modify this file, bump
# the number in this .bbappend to reflect the change and force a re-build.
PR =. "+runit-r1"

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

