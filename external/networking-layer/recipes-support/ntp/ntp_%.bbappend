# Extend the search path to here first...  We're overlaying the stock one
# from the meta-networking layer (Since it's largely non-functional for anything
# other than OUR providing time to someone using us as a server...) to support
# tying back to the Internet NTP pool cloud for our uses.  If you need to
# modify this further so it ties to your specific NTP configuation, you should
# just .bbappend like we're doing here and be lower in the processing order
# than our layer which lets you override our mod here and just drop it in files
# or wherever you're extending the path search to.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# This is an annex of the original metadata.  So, if you modify this file, bump
# the number in this .bbappend to reflect the change and force a re-build.
PR =. "+runit-r1"

# Add the services sets we provide for this to be a runit based package set...
SRC_URI += " \
    file://sv/isc-ntpd/run \
    "

# Next, make it a runit capable package...
inherit runit

# And declare it to be auto-enabled as default with logging.
RUNIT-SERVICES = "DEFAULT"
RUNIT_DEFAULT_MODS = "log"

# Now we're going to clean out cruft that would be parts of either a systemd
# or a sysvinit system.  They're under foot and NOT used/needed for a runit
# based system (You're not trying to do this with runit at the same time,
# riiight?).  Then we're going to bolt our additional file changes onto the
# right packaging groups so that they have their run files packaged and in
# the right places along with the enables hooked in properly via the runit
# .bbclass mods.
#
# This may seem...clumsy...and inefficient.  Yes.  It is.  The thing is, if you
# want first-class support of runit, you will need to do this as it's less messy
# and inefficient than the alternative that you have without getting a bunch
# of fixes/mods accepted upstream into the Yocto project itself.
clean_up_other_init_cruft() {
    # Nuke any sysvinit stuff.
    rm -rf ${D}${sysconfdir}/init.d

    # Nuke any systemd stuff...we flatly don't want/need any of it in this mode.
    rm -rvf ${D}${systemd_unitdir}
}
do_install[postfuncs] += " clean_up_other_init_cruft "

# Since this is a complex multi-packaging recipe, the runit stuff won't
# auto-package right for us.  Tell bitbake what it needs to know to do
# this right for the recipe.
FILES:${PN} += " \
    /etc/runit \
    /etc/sv \
    "