DESCRIPTION = "Baseline runit services configuration set"
LICENSE = "MIT"
# Ignore the odd move "up" a directory here.  It's because the COPYING belongs
# in the "project"- which has a CMake based C source set for where we're putting
# ${S} to inside this all.
LIC_FILES_CHKSUM = "file://../COPYING;md5=91cc138cfd680c457be3678a29aaf4a3"

RDEPENDS:${PN} = " \
    millisleep \
    coreutils \
    psmisc \
    ncurses \
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
    file://rsm \
    file://csrc/CMakeLists.txt \
    file://csrc/halt.c \
    file://csrc/halt.8 \
    file://csrc/pause.c \
    file://csrc/pause.1 \
    file://core-services/00-hwclock.sh \
    file://core-services/00-pseudofs.sh \
    file://core-services/01-kmods.sh\
    file://core-services/01-static-devnodes.sh \
    file://core-services/02-udev.sh \
    file://core-services/04-filesystems.sh \
    file://core-services/04-swap.sh \
    file://core-services/04-system-dtbo-load.sh \
    file://core-services/05-misc.sh \
    file://core-services/05-volatiles.sh \
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
    "

S = "${WORKDIR}/csrc"

# We're runit and additionally CMake as a recipe.  CMake's in
# the mix for the purposes of scooping up a few /sbin binaries
# that we need for proper function of our base services set.
inherit runit cmake

# Make the recipe insensitive to where it needs to be dropped
# in terms of the rootfs.  /sbin for "normal" mode, /usr/sbin
# if "usrmerge" is specified for the distro config.  This makes
# it quite a bit cleaner than previous.
EXTRA_OECMAKE += " \
    -DCMAKE_INSTALL_SBINDIR='${sbindir}' \
    "

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
    install -d -m 0755 ${D}${sbindir}
    install -m 0644 ${WORKDIR}/00-volatiles ${D}/etc/default/volatiles
	install -m 0755 ${WORKDIR}/1 ${D}/etc/runit
	install -m 0755 ${WORKDIR}/2 ${D}/etc/runit
	install -m 0755 ${WORKDIR}/3 ${D}/etc/runit
    install -m 0755 ${WORKDIR}/functions ${D}/etc/runit
    install -m 0755 ${WORKDIR}/modules-load ${D}${sbindir}
    install -m 0755 ${WORKDIR}/shutdown ${D}${sbindir}
    install -m 0755 ${WORKDIR}/rsm ${D}${sbindir}

    # Symlink a few things to one of the binaries that we just moved...
    # It's a multicall dispatch much like busybox is...
    ln -s ${sbindir}/halt ${D}${sbindir}/poweroff
    ln -s ${sbindir}/halt ${D}${sbindir}/reboot
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

    # Iterate our list... (Note: Leave "tmp" and all it entails IN here...it's a workaround
    # for something bitbake can't do expansion-wise...)  Handle "console" here transparently
    # because we want it on anything where the console isn't a serial one on the device.
    tmp="${SERIAL_CONSOLES}"
    if [ -z "$tmp" ] ; then
        # Got nothing...we'll try for supporting just the virtual console.
        svcpath="${D}${runit-svcdir}/getty-console"
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
    else
        # Process out our list.  This tells bootloader, initial kernel to use those
        # as consoles.  We want to do logins right now against all of them.
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


