DESCRIPTION = "Void Service Manager (vsv) - Enhanced functionality runit sv wrapper"
HOMEPAGE = "https://www.daveeddy.com/2018/09/20/vsv-void-service-manager/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9b9ce9e1eb451c0853b7586118435f54"

SRC_URI = " \
    git://github.com/bahamas10/vsv.git;protocol=https \
    "

SRCREV = "v${PV}"

# This is just a highly specialized BASH helper script and wants some stuff
# from psmisc...which is actually a bit useful by and of itself...
RDEPENDS:${PN} = "bash psmisc"

S = "${WORKDIR}/git"

# Cheat and hotpatch the scripting on the fly with sed in the patch phase.
# (This way we don't have to come up with a new patch for the pathing each
#  time there's a release of the script and we don't have to kludge up pathing
#  to match the stuff Void's done with everything to suit themselves...)
do_patch() {
    cp ${S}/vsv ${S}/vsv.patched
    sed -i "s/\/var\/service/\/etc\/runit\/runsvdir\/current/g" ${S}/vsv.patched
}

do_compile[noexec] = "1"

do_install() {
    install -d ${D}/usr/sbin
    install -m 755 ${S}/vsv.patched ${D}/usr/sbin/vsv
}

FILES:${PN} = "/usr/sbin/vsv"