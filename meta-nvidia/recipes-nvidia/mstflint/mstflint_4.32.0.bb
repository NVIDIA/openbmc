SUMMARY = "Mellanox firmware burning and diagnostics tools"
DESCRIPTION = "This package contains a burning tool for Mellanox manufactured HCA/NIC cards"
HOMEPAGE = "https://github.com/Mellanox/mstflint"

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "\
    file://LICENSE;md5=79e20039679d6414176a6a04804e40be \
    file://COPYING;md5=37684ff4dc627e8779d1dba945d8724b \
    file://license_map.yaml;md5=2c3cdef9d92aa3b870a62501f77cbfb7 \
    "

PV = "4.32.0-1"

FILESPATH = "${THISDIR}/files"
SRC_URI = "git://github.com/Mellanox/mstflint.git;protocol=https;branch=master"
SRCREV = "40b3fd760d8253e0e374bf6a519fc0b569b804a6"

PACKAGES =+ "${PN}-flint"

DEPENDS += "openssl zlib"
RDEPENDS:${PN} += "openssl zlib"
RDEPENDS:${PN}-flint += "openssl zlib"

S = "${WORKDIR}/git"

# Saves ~100KiB
CFLAGS += "-Oz"
CXXFLAGS += "-Oz"

inherit autotools pkgconfig

# Keep static libs around because mstflint is compiled statically
DISABLE_STATIC = ""
EXTRA_OECONF += "\
    --enable-i2c \
    --disable-inband \
    "
# HACK: See https://jirasw.nvidia.com/browse/DGXOPENBMC-16931 for removal
EXTRA_OEMAKE:append = " libresource_dump_common_la_CXXFLAGS+='-I$(top_srcdir)'"

FILES:${PN}-flint = "${bindir}/mstflint"
