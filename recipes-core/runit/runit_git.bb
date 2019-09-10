SUMMARY = "runit init and services system"
LICENSE = "BSD"
HOMEPAGE = "https://github.com/madscientist42/runit"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=3cf56266ad83a2793f171707969e46d1"

SRC_URI = " \
	git://github.com/madscientist42/runit.git;protocol=https \
	"

SRCREV = "17d63c7068cc6e6ee0c0abde9457ab3417d7e0d2"

S = "${WORKDIR}/git"

inherit cmake 

# Make our lives a bit easier.  While the install works RIGHT for CMake for the packaging, we
# want a bit of init-scripting legerdemain installed up-front as a part of this package (We
# want/need, to make our lives easier, to establish the /etc/runit/runsvdir directory structure
# enough to count for setting "current" that belongs to runit to be linked to "default"
setup_runsvdir() {
    install -d -m 0755 ${D}/etc/sv
    install -d -m 0755 ${D}/etc/runit/runsvdir
    install -d -m 0755 ${D}/etc/runit/runsvdir/default
    install -d -m 0755 ${D}/etc/runit/runsvdir/single
    ln -s /etc/runit/runsvdir/default ${D}/etc/runit/runsvdir/current
    ln -s /etc/sv ${D}/service
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit', 'setup_runsvdir', '', d)} "
FILES_${PN} += "/service"

# Do some additional OpenEmbedded specific tasks for install if we're told we're using runit-init as init.
do_runit_init_as_init() {
	# Tie to init, so we run instead of busybox or sysvinit
    install -d ${D}/sbin
	ln -s /usr/sbin/runit ${D}/sbin/init
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit-init', 'do_runit_init_as_init', '', d)} "
