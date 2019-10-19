# Extend the search path to here first...
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Now, extend things to support the service we're providing...it's not 
# named the same as we are because this is the DM for Enlightenment anyhow.
SRC_URI += " \
    file://sv/enlightenment/run \
    "

inherit runit

RUNIT-SERVICES = "DEFAULT"

