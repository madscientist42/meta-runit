DESCRIPTION = "Baseline runit services configuration set"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING;md5=3cf56266ad83a2793f171707969e46d1"

SRC_URI = " \
    file://COPYING \
    file://sv \
    "

S = "${WORKDIR}"

inherit runit

# We want some of the services to be template ones (Like the getty-generic one...)
# so, we'll be enabling the services selectively as they get added past the core
# run-once stuff in "initscripts" as appended by the .bbappend.
RUNIT-SERVICES = " \
    "

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
            install -d ${D}{runit_svcdir}/getty-${ttydev}
            cd ${D}{runit_svcdir}/getty-${ttydev}
            ln -s ../getty-generic/run run
            ln -s ../getty-generic/run finish
            echo 'GETTY_ARGS="-L"' > conf
            echo 'if [ -x /sbin/agetty -o -x /bin/agetty ]; then' >> conf
	        echo '    # util-linux specific settings' >> conf
	        echo '    GETTY_ARGS="${GETTY_ARGS} -8"' >> conf
            echo 'fi' >> conf
            echo 'BAUD_RATE=${baudrate}' >> conf
            echo 'TERM_NAME=vt100' >> conf
            cd ${D}{runit_runsvdir}/default
            ln -s ${D}{runit_svcdir}/getty-${ttydev} 
		done
	fi    
}
DO_SERIAL_CONSOLES = "${@bb.utils.contains('DISTRO_FEATURES', 'sysvinit', '', 'install_serial_consoles', d)}"
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', '${DO_SERIAL_CONSOLES}', '', d)} "

