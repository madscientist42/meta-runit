# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Next, make it a runit capable package...
inherit runit

# This is an annex of the original metadata.  So, if you modify this file, bump
# the number in this .bbappend to reflect the change and force a re-build.
PR =. "+runit-r1"

# Add the services set(s) we're supplying...
SRC_URI += " \
    file://sv/gpsd/run \
    file://sv/gpsd/check \
    "

# Some default parameters for the defaults re-generation engine below...
# These defaults should make sense for a device that's either hotplugged
# as a USB device or for units specified out in device tree terms.  Options
# is a catch-all bucket for anything not defined here...  We will generate
# the default options string from that all...
#
# You will need to override them for your HW targets accordingly.
GPSD_SOCKET ?= "/run/gpsd.sock"
GPSD_DEVICES ?= "/dev/gps0"
GPSD_SPEED ?= ""
GPSD_PORT ?= ""
GPSD_OPTIONS ?= ""
DEFAULTS_FILE ?= "${D}/etc/default/gpsd.default"

# Now, make this cleaner and more predictable versus the odd stuff
# the gpsd people did for their
regenerate_defaults() {
    # Get the basics out of the way...
    echo "SOCKET=\"${GPSD_SOCKET}\"" > ${DEFAULTS_FILE}
    echo "DEVICES=\"${GPSD_DEVICES}\"" >> ${DEFAULTS_FILE}

    # Build out the options for things like speed and port which are very
    # specific command line options for serial port or TCP/UDP providers.
    OPTIONS_LIST="${GPSD_OPTIONS}"

    if [ ! -z "${GPSD_SPEED}" ] ; then
        OPTIONS_LIST="$OPTIONS_LIST -s ${GPSD_SPEED}"
    fi

    if [ ! -z "${GPSD_PORT}" ] ; then
        OPTIONS_LIST="$OPTIONS_LIST -S ${GPSD_PORT}"
    fi

    echo "OPTIONS=\"${OPTIONS_LIST## }\"" >> ${DEFAULTS_FILE}
}
do_install[postfuncs] += " regenerate_defaults "


# And declare it to be auto-enabled as default if nobody overrides it.
RUNIT-SERVICES ?= "DEFAULT"
RUNIT_DEFAULT_MODS = "log"

