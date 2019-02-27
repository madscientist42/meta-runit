# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Add the services set(s)...
SRC_URI += " \
    file://sv/bluetooth/run \
    file://sv/obex/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"

# Follow this up by updating packaging accordingly...
RUNIT_BT_SVCS = " \
    ${runit-svcdir}/bluetooth/run \
    ${runit-runsvdir}/bluetooth \
    "
FILES_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${RUNIT_BT_SVCS}', '', d)}"

RUNIT_OBEX_SVCS = " \
    ${runit-svcdir}/obex/run \
    ${runit-runsvdir}/obex \
    "
FILES_${PN}-obex += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${RUNIT_OBEX_SVCS}', '', d)}"
    
    
