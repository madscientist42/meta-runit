DESCRIPTION = "Baseline runit services configuration set"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=91cc138cfd680c457be3678a29aaf4a3"

RDEPENDS_${PN} = " \
    millisleep \
    coreutils \
    ${@bb.utils.contains('DISTRO_FEATURES', 'socklogd', 'socklogd', '', d)} \
    "

SRC_URI = " \
    file://COPYING \
    file://00-volatiles \
    file://1 \
    file://2 \
    file://3 \
    file://functions \
    file://modules-load \
    file://shutdown \
    file://svstats \
    file://halt.c \
    file://pause.c \
    file://CMakeLists.txt \
    file://core-services/00-hwclock.sh \
    file://core-services/00-pseudofs.sh \
    file://core-services/01-static-devnodes.sh \
    file://core-services/02-kmods.sh\
    file://core-services/03-console-setup.sh \
    file://core-services/03-dtbo-load.sh \
    file://core-services/03-filesystems.sh \
    file://core-services/03-udev.sh \
    file://core-services/04-swap.sh \
    file://core-services/05-misc.sh \
    file://core-services/05-populate-volatile.sh \
    file://core-services/06-postinsts.sh \
    file://core-services/06-sysctl.sh \
    file://sv/hwclock/run \
    file://sv/hwclock/finish \
    file://sv/getty-generic/run \
    file://sv/getty-generic/finish \
    file://sv/sulogin/run \
    file://sv/syslog/run \
    file://sv/klog/run \
    file://socklogd/sv/syslog/run \
    file://socklogd/sv/klog/run \
    "

S = "${WORKDIR}"

# We're runit and additionally CMake as a recipe.  CMake's in 
# the mix for the purposes of scooping up a few /sbin binaries
# that we need for proper function of our base services set.
inherit runit cmake

# We want some of the services to be template ones (Like the getty-generic one...)
# so, we'll be enabling the services selectively here.  It should be noted that 
# we're making a bit of a gearshift if you have socklogd set as a distro feature.
# If you're using socklogd, there's no need to use syslogd,
RUNIT-SERVICES = " \
    sulogin;single \
    ${@bb.utils.contains('DISTRO_FEATURES', 'socklogd', 'syslog;log', 'syslog', d)} \
    klog \
    hwclock \
    "

# IF we're set to run with runit in the mix, copy in some new things...
install_runit_initscripts() {
    # Set up the core-services...
    install -d -m 0755 ${D}/etc/default/volatiles
	install -d -m 0755 ${D}/etc/runit
	install -d -m 0755 ${D}/etc/runit/core-services
    install -d -m 0755 ${D}/sbin
    install -m 0644 ${WORKDIR}/00-volatiles ${D}/etc/default/volatiles
	install -m 0755 ${WORKDIR}/1 ${D}/etc/runit
	install -m 0755 ${WORKDIR}/2 ${D}/etc/runit
	install -m 0755 ${WORKDIR}/3 ${D}/etc/runit
    install -m 0755 ${WORKDIR}/functions ${D}/etc/runit
    install -m 0755 ${WORKDIR}/modules-load ${D}/sbin
    install -m 0755 ${WORKDIR}/shutdown ${D}/sbin
    install -m 0755 ${WORKDIR}/svstats ${D}/sbin
	for I in ${WORKDIR}/core-services/* ; do
		install -m 0755 $I ${D}/etc/runit/core-services
	done 

    # Put some stuff that was in ${D}/usr/sbin into ${D}/sbin because
    # it's easier to postprocess move them into the right place than
    # to try to make the CMake do the "right things..."
    mv ${D}/usr/sbin/* ${D}/sbin
    rm -rf ${D}/usr

    # Symlink a few things to one of the binaries that we just moved...
    ln -s /sbin/halt ${D}/sbin/poweroff
    ln -s /sbin/halt ${D}/sbin/reboot
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'install_runit_initscripts', '', d)} "

# Handle the getty part of the SERIAL_CONSOLES specified in here.
install_serial_consoles() {
    # Handle the OLD single case- if we don't have the SERIAL_CONSOLES entry defined and have SERIAL CONSOLE
    # defined instead, pour it into the other with the expected formatting...
    if [ -z "${SERIAL_CONSOLES}" ] ; then
        echo Handling old method...
        export SERIAL_CONSOLES=`echo "${SERIAL_CONSOLE}" | sed 's/ /\;/g'` 
    fi 

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

# Now, handle overriding the case where we have been told to use socklogd for things, and to quietly 
# shift gears to using it for syslog, etc...  There's a few /etc/sv entries we need to overwrite in the install...
copy_socklogd_support() {
        cp -rap --no-preserve=ownership ${WORKDIR}/socklogd/sv/* ${D}${runit-svcdir}
        chmod u+x ${D}${runit-svcdir}/*/run  
}
DO_SOCKLOGD_SUPPORT = "${@bb.utils.contains('DISTRO_FEATURES', 'socklogd', 'copy_socklogd_support', '', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_SOCKLOGD_SUPPORT}', '', d)} "


