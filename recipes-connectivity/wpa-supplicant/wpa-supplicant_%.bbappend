# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Add the services set(s)...
SRC_URI += " \
    file://sv/wpa_supplicant/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"
RUNIT_DEFAULT_MODS = "log"


