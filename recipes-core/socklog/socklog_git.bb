SUMMARY = "socklogd Socket/System/Kernel logging daemon"
LICENSE = "BSD"
HOMEPAGE = "https://github.com/madscientist42/runit"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=82284e4f2ea938e061cb20d953c26189"

SRC_URI = " \
	git://github.com/madscientist42/socklog.git;protocol=https \
	"

SRCREV = "6bfbef8306e8f07e9ae3981e31b33decdcd5715d"

S = "${WORKDIR}/git"

inherit cmake

PACKAGES = "${PN}-src ${PN}d ${PN}d-dbg"

FILES:${PN}-src = " \
    /usr/src \
    "
FILES:${PN}d = " \
    /usr/sbin/socklog-check \
    /usr/sbin/uncat \
    /usr/sbin/tryto \
    /usr/sbin/nanoklogd \
    /usr/sbin/socklog-conf \
    /usr/sbin/socklog \
    "    

FILES:${PN}d-dbg = " \
    /usr/sbin/.debug/socklog-check \
    /usr/sbin/.debug/uncat \
    /usr/sbin/.debug/tryto \
    /usr/sbin/.debug/nanoklogd \
    /usr/sbin/.debug/socklog-conf \
    /usr/sbin/.debug/socklog \
    "    

