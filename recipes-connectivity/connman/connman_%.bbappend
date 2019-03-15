# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Add the services set(s)...
SRC_URI += " \
    file://sv/connman/run \
    ${@bb.utils.contains('COMBINED_FEATURES', 'iwd', 'file://iwd/config', 'file://wpa-supplicant/config',d)} \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"

# One last thing, set up the gear-shifted config file so we can use 
# the right and desired wireless, etc. manager entries for our daemon...
copy_connman_config(){
    install -m 0644 ${WORKDIR}/config ${D}${sysconfdir}/sv/connman 
}
do_install[postfuncs] += "copy_connman_config "


