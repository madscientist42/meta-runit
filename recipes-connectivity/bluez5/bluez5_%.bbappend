# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add the services set(s)...
SRC_URI += " \
    file://sv/bluetooth/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"
RUNIT_DEFAULT_MODS = "log"

# Follow this up by updating packaging accordingly...
RUNIT_BT_SVCS = " \
    ${runit-svcdir}/bluetooth/run \
    ${runit-runsvdir}/bluetooth \
    "
RUNIT_BT_REMOVES = " \
    ${sysconfdir}/init.d/bluetooth \
    ${datadir}/dbus-1 \
    "
FILES:${PN}:append = "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${RUNIT_BT_SVCS}', '', d)}"
FILES:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${RUNIT_BT_REMOVES}', '', d)}"

# Now, then, let's ENFORCE the above removes from the list so that it doesn't
# complain about them as they might happen under right conditions....
do_deletes() {
    for DELETE in ${RUNIT_BT_REMOVES}; do
        rm -rvf ${D}/$DELETE
    done
}
do_install[postfuncs] = " do_deletes "

