# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

WIFI_MGR = "${@bb.utils.contains('DISTRO_FEATURES', 'iwd', 'iwd', 'wpa-supplicant' ,d)}"

# Add the services set(s)...
SRC_URI += " \
    file://sv/connman/run \
    file://${WIFI_MGR}.config \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"

# One last thing, set up the gear-shifted config file so we can use 
# the right and desired wireless, etc. manager entries for our daemon...
copy_connman_config(){
    install -m 0644 ${WORKDIR}/${WIFI_MGR}.config ${D}${sysconfdir}/sv/connman/config 
}
do_install[postfuncs] += "copy_connman_config "


