DESCRIPTION = "elogind, the logind framework from systemd extracted out from systemd"
HOMEPAGE = "https://github.com/elogind/elogind"
LICENSE = "LGPL-2.1-or-later"
LIC_FILES_CHKSUM = "file://LICENSE.LGPL2.1;md5=4fbd65380cdd255951079008b364516c"

inherit meson pkgconfig

CORE_DEPENDENCIES = " \
    libcap \
    libpam \
    "

DEPENDS = " \
    ${CORE_DEPENDENCIES} \
    gperf-native \
    python3-jinja2-native \
    eudev \
    acl \
    "

RDEPENDS:${PN} = " \
    ${CORE_DEPENDENCIES} \
    libudev \
    libacl \
    "

SRC_URI += " \
    git://github.com/elogind/elogind.git;protocol=https;branch=v255-stable \
    "

SRCREV = "36917dda508996eedbb0b4b24af4e2dfe911179d"
S = "${WORKDIR}/git"

EXTRA_OEMESON = " \
    -Dmode=release \
    "

# Do this lazily- all installed needs to be packaged...
FILES:${PN} = " \
    /etc \
    /usr \
    /var \
    "