FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Attach runit support...
inherit runit
RDEPENDS_${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'runit', '', d)}"
	       	  
# Append a few new files for the purposes of providing runit scripting- anything else is a base 
# default/one-shot service or a shutdown...
SRC_URI += " \
	file://1 \
	file://2 \
	file://3 \
    file://functions \
	file://core-services/00-pseudofs.sh \
	file://core-services/01-static-devnodes.sh \
	file://core-services/02-kmods.sh\
	file://core-services/02-udev.sh \
	file://core-services/03-console-setup.sh \
	file://core-services/03-filesystems.sh \
	file://core-services/04-swap.sh \
	file://core-services/05-misc.sh \
	"

# IF we're set to run with runit in the mix, copy in some new things...
install_runit_initscripts() {
	install -d -m 0755 ${D}/etc/runit
	install -d -m 0755 ${D}/etc/runit/core-services
	install -m 0755 ${WORKDIR}/1 ${D}/etc/runit
	install -m 0755 ${WORKDIR}/2 ${D}/etc/runit
	install -m 0755 ${WORKDIR}/3 ${D}/etc/runit
	for I in ${WORKDIR}/core-services/* ; do
		install -m 0755 $I ${D}/etc/runit/core-services
	done 
    # Wedge in some items from the other installs from the stock sysvinit...
    mv ${D}/etc/init.d/devpts.sh ${D}/etc/runit/core-services/02-devpts.sh
    mv ${D}/etc/init.d/populate-volatile.sh ${D}/etc/runit/core-services/04-populate-volatile.sh
    if [ -e ${D}/etc/init.d/rmnologin.sh ] ; then
        mv ${D}/etc/init.d/rmnologin.sh ${D}/etc/runit/core-services/04-rmnologin.sh
    fi
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'install_runit_initscripts', '', d)} "

# IF we're set to run with runit as init, we need to clean some junk back out. 
# (I know, I know...we need to properly integrate and skip unneeded steps...
#  Once this is on a more even keel with systemd's integration, we can revisit...)
# We don't, for example, need the rc<x>.d directories in the system anymore.
remove_sysvinit_unneeded() {
    rm -rvf ${D}/etc/rc*.d
    rm -rvf ${D}/etc/init.d
}
DO_CLEANUP = "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', '', 'remove_sysvinit_unneeded', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit-init', '${DO_CLEANUP}', '', d)} "



