SUMMARY = "runit init and services system"
LICENSE = "BSD"
HOMEPAGE = "https://github.com/madscientist42/runit"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=3cf56266ad83a2793f171707969e46d1"

PROVIDES += "virtual/runit virtual/init"

SRC_URI = " \
	git://github.com/madscientist42/runit.git;protocol=https \
	"

SRCREV = "38c05437e0edaf26d621819156bf4f4a5b234ef3"

S = "${WORKDIR}/git"

inherit cmake 

# Do some additional OpenEmbedded specific tasks for install
do_install_append() {
	# Tie to init, so we run instead of busybox or sysvinit
	ln -s /sbin/runit-init /sbin/init
}
