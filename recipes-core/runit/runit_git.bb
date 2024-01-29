SUMMARY = "runit init and services system"
LICENSE = "BSD-2-Clause"
HOMEPAGE = "https://github.com/madscientist42/runit"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=3cf56266ad83a2793f171707969e46d1"

SRC_URI = " \
	git://github.com/madscientist42/runit.git;protocol=https;branch=master \
	"

SRCREV = "e27d217f8fc6c202a43001333b31a259efeab08c"

S = "${WORKDIR}/git"

# Cheat a bit.  We used to be able to specify out core services files by
# the initscripts hooks, so...since this broke at some point, to make this
# generic- and you rather can't do without these core services files or
# somesuch as that, you're going to see this RDEPEND on it or something 
# like it (.bbappend it!!  Seriously- this is the baseline for this layer
# and you want to override this RDEPENDS if you're not merely extending
# that recipe.)
RDEPENDS:${PN} += "runit-base-services"

inherit cmake

# Make the recipe insensitive to where it needs to be dropped
# in terms of the rootfs.  /sbin for "normal" mode, /usr/sbin
# if "usrmerge" is specified for the distro config.  This makes
# it quite a bit cleaner than previous.
EXTRA_OECMAKE += " \
    -DCMAKE_INSTALL_SBINDIR='${sbindir}' \
    "


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
FILES:${PN} += "/service"

# Do some additional OpenEmbedded specific tasks for install if we're told we're using runit-init as init.
do_runit_init_as_init() {
	# Tie to init, so we run instead of busybox or sysvinit
    install -d ${D}${sbindir}
	ln -s ${sbindir}/runit ${D}${sbindir}/init
}
do_install[postfuncs] += "${@bb.utils.contains('DISTRO_FEATURES', 'runit-init', 'do_runit_init_as_init', '', d)} "
