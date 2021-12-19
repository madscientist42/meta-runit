# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the services set(s)...
SRC_URI += " \
    file://sv/gpsd/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default if nobody overrides it.
RUNIT-SERVICES ?= "DEFAULT"
RUNIT_DEFAULT_MODS = "log"

