SUMMARY = "runit init and services system"
LICENSE = "BSD"
HOMEPAGE = "https://github.com/madscientist42/runit"
LIC_FILES_CHKSUM = "file://COPYING.md;md5=4b85004ff83dd932ff28f7f348fb2a28"

PROVIDES += "virtual/runit"

SRC_URI = " \
	git://github.com/madscientist42/runit.git;protocol=https \
	"

SRCREV = "38c05437e0edaf26d621819156bf4f4a5b234ef3"

S = "${BUILDDIR}/git"

inherit cmake 
