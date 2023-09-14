# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# This is an annex of the original metadata.  So, if you modify this file, bump
# the number in this .bbappend to reflect the change and force a re-build.
PR =. "+runit-r1"

# Now, extend things to support the service we're providing...it's not
# named the same as we are because this is the DM for Enlightenment anyhow.
SRC_URI += " \
    file://sv/enlightenment/run \
    "

inherit runit

RUNIT-SERVICES = "DEFAULT"



