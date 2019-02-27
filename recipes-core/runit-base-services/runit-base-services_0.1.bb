DESCRIPTION = "Baseline runit services configuration set"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://COPYING \
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
    file://sv/getty-generic/run \
    file://sv/getty-generic/finish \
    "

S = "${WORKDIR}"

inherit runit

# We want some of the services to be template ones (Like the getty-generic one...)
# so, we'll be enabling the services selectively as they get added past the core
# run-once stuff in "initscripts" as appended by the .bbappend.
RUNIT-SERVICES = " \
    "

# IF we're set to run with runit in the mix, copy in some new things...
install_runit_initscripts() {
    # Set up the core-services...
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

# Handle the getty part of the SERIAL_CONSOLES specified in here.
install_serial_consoles() {
	if [ ! -z "${SERIAL_CONSOLES}" ] ; then
        # Iterate our list... (Note: Leave "tmp" and all it entails IN here...it's a workaround
        # for something bitbake can't do expansion-wise...)
        tmp="${SERIAL_CONSOLES}"
		for entry in $tmp ; do
            # Fetch out the tty device and the baudrate for each entry in the SERIAL_CONSOLES param...
			baudrate=`echo $entry | sed 's/\;.*//'`
			ttydev=`echo $entry | sed -e 's/^[0-9]*\;//' -e 's/\;.*//'`

            # With it in hand, dynamically generate runit service entries and enable them in the 
            # default set out of box...
            svcpath="${D}${runit-svcdir}/getty-${ttydev}"
            conffile="${svcpath}/conf"
            install -d ${svcpath}
            ln -s ../getty-generic/run ${svcpath}
            ln -s ../getty-generic/finish ${svcpath}
            echo 'GETTY_ARGS="-L"' > ${conffile}
            echo 'if [ -x /sbin/agetty -o -x /bin/agetty ]; then' >> ${conffile}
	        echo '    # util-linux specific settings' >> ${conffile}
	        echo '    GETTY_ARGS="${GETTY_ARGS} -8"' >> ${conffile}
            echo 'fi' >> ${conffile}
            echo 'BAUD_RATE='$baudrate >> ${conffile}
            echo 'TERM_NAME=vt100' >> ${conffile}
            ln -s ${runit-svcdir}/getty-${ttydev} ${D}${runit-runsvdir}/default
		done
	fi    
}
DO_SERIAL_CONSOLES = "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', '', 'install_serial_consoles', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_SERIAL_CONSOLES}', '', d)} "


