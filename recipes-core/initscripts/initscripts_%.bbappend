FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Attach runit support...
inherit runit
	       	  
# Append a few new files for the purposes of providing runit scripting
SRC_URI += " \
	file://1 \
	file://2 \
	file://3 \
	file://core-services/00-pseudofs.sh \
	file://core-services/01-static-devnodes.sh \
	file://core-services/02-kmods.sh\
	file://core-services/02-udev.sh \
	file://core-services/03-console-setup.sh \
	file://core-services/03-filesystems.sh \
	file://core-services/04-swap.sh \
	file://core-services/05-misc.sh \
	file://core-services/06-sysctl.sh \
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
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'install_runit_initscripts', '', d)} "

