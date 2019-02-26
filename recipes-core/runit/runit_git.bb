SUMMARY = "runit init and services system"
LICENSE = "BSD"
HOMEPAGE = "https://github.com/madscientist42/runit"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=3cf56266ad83a2793f171707969e46d1"

SRC_URI = " \
	git://github.com/madscientist42/runit.git;protocol=https \
	"

SRCREV = "38c05437e0edaf26d621819156bf4f4a5b234ef3"

S = "${WORKDIR}/git"

inherit cmake 

# Do some additional OpenEmbedded specific tasks for install if we're told we're using runit-init as init.
do_runit-init_as_init() {
	# Tie to init, so we run instead of busybox or sysvinit
	cd ${D}/sbin
	ln -s runit-init init
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit-init', 'do_runit-init_as_init', '', d)} "
