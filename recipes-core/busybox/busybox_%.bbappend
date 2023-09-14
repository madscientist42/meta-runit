# Extend the search path to here first...we're intercepting a few config items.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# This is an annex of the original metadata.  So, if you modify this file, bump
# the number in this .bbappend to reflect the change and force a re-build.
PR =. "+runit-r1"
