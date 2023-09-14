# Extend the search path to here first...
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# Add a PR component for our contributions to this recipe.  If you change the guts in
# the .bbappend, bump the number here...
PR =. "+runit-r1"

inherit runit

# Add the services set(s)...
SRC_URI += " \
    file://sv/kea-dhcp4 \
    file://sv/kea-dhcp6 \
    file://sv/kea-dhcp-ddns \
    "

# And declare it to be auto-enabled as default...
RUNIT-SERVICES = "DEFAULT"

