LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=a832eda17114b48ae16cda6a500941c2"

DEPENDS = " \
    json-c \
    ${@bb.utils.contains('PTEST_ENABLED', '1', 'gtest', '', d)} \
    ${@bb.utils.contains('PTEST_ENABLED', '1', 'gmock', '', d)} \
    "

PV = "1.0+git${SRCPV}"
SRCREV = "55968b12e1e0aaaf0e70215e47d8a93706dab21b"

SRC_URI = "git://github.com/openbmc/libcper.git;protocol=https;branch=main"

S = "${WORKDIR}/git"

inherit pkgconfig meson ptest

EXTRA_OEMESON = " \
    -Dtests=${@bb.utils.contains('PTEST_ENABLED', '1', 'enabled', 'disabled', d)} \
"
