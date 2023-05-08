DESCRIPTION = "Millisecond resolution sleep for scripting use"
HOMEPAGE = "https://github.com/madscientist42/millsleep"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://COPYING;md5=1c9328c8e853d744244bc1653fcb43d1"

SRC_URI = "git://github.com/madscientist42/millsleep.git;protocol=https;branch=master"
SRCREV = "8bb8153e1d5fec9557e5a8b2e883bedd25565cfd"

S = "${WORKDIR}/git"

inherit cmake

