# if the feature is turned on for the Distro, we want to FORCE depenency to ensure
# "runit" gets packaged on the target image...
RDEPENDS_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'runit runit-base-services', '', d)}"

# Set up some default behaviors
RUNIT-SERVICES ??= ""
runit-svcdir = "/etc/sv"
runit-runsvdir = "/etc/runit/runsvdir"

# This class will be included in any recipe that supports runit services configs,
# even if runit is not in DISTRO_FEATURES.  As such don't make any changes
# directly but check the DISTRO_FEATURES first.
python __anonymous() {
    # If the distro features have runit but not sysvinit, inhibit update-rcd
    # from doing any work so that pure-runit based images don't have redundant init
    # files/links.
    if bb.utils.contains('DISTRO_FEATURES', 'runit', True, False, d):
        if not bb.utils.contains('DISTRO_FEATURES', 'sysvinit', True, False, d):
            d.setVar("INHIBIT_UPDATERCD_BBCLASS", "1")
}

# Services specs should be set up in the files under sv in the files directory 
# and specfied at least as a directory (Preferably, each piece part in the 
# tree to support devtool properly) 
install_runit_services() {
    if [ -d ${WORKDIR}/sv ] ; then 
        # Ensure we've got a proper services directory in the packaging...
        mkdir -p ${D}${runit-svcdir}

        cp -rap --no-preserve=ownership ${WORKDIR}/sv/* ${D}${runit-svcdir}
    fi
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'install_runit_services', '', d)} "

# One of the other things we need to do is if we've got a corresponding service in
# the services directory for ${PN}, then we need to nuke the sysvinit entries.
# because we have a service in place.  (We'll handle any init.d entries that are
# left in there, but as people add services for runit in recipes or as the overlays
# in this metadata layer, we want to remove them...)
# 
# FIXME - This just blindly removes everything in the packaging for sysvinit stuff
#         For now, this is, "fine," but needs to be revisited with "better".
cleanup_sysvinit_dirs() {
    rm -rvf ${D}/etc/rc*.d
}
DO_SYSVINIT_CLEANUP = "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', '', 'cleanup_sysvinit_dirs', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_SYSVINIT_CLEANUP}', '', d)} "

# Services can be enabled in one of two ways or left disabled per package.
# If you specify service names (as they're specified in the packaging
# under the "sv" directory...) you can specify, default (nothing), 
# ran once (.once), and provide basic logging services (.log), with the
# dot values appended to the end in .once.log order for each desired.
# Additionally, if you specify, "DEFAULT" in all caps in that variable,
# it will presume all services in the package are set to default ran.
enable_default_services() {
	install -d ${D}${runit-runsvdir}
	install -d ${D}${runit-runsvdir}/once
	install -d ${D}${runit-runsvdir}/default   
    for svc in ${D}${runit-svcdir}; do
        ln -s ${runit-svcdir}/svc ${D}${runit-runsvdir}/default
    done
}

enable_services() {
	install -d ${D}${runit-runsvdir}
	install -d ${D}${runit-runsvdir}/once
	install -d ${D}${runit-runsvdir}/default   

	for svc in ${RUNIT-SERVICES}; do
		log=0
		servicename=$(basename $oncename .once)
		if [ "$servicename" != "$oncename" ]; then
			# Goes into the default services dir.
			linkpath="default"
		else
			# Goes into the once services dir.
			linkpath="once"
		fi
		ln -s ${runit-svcdir}/${servicename} ${D}${runit-runsvdir}/${linkpath}

		# FIXME - Add logging support...
		
	done
}
DO_DEFAULT_SVCS = "${@bb.utils.contains('RUNIT-SERVICES', 'DEFAULT', 'enable_default_services', 'enable_services', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_DEFAULT_SVCS}', '', d)} "

