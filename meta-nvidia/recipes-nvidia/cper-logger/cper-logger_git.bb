SUMMARY = "Logger for CPERs"
DESCRIPTION = "The CPER logger decodes CPERs received & logs them to the EventLog"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

DEPENDS = " \
  libcper \
  phosphor-logging \
  sdbusplus \
  nlohmann-json \
  ${@bb.utils.contains('PTEST_ENABLED', '1', 'gtest', '', d)} \
  ${@bb.utils.contains('PTEST_ENABLED', '1', 'gmock', '', d)} \
"

SRC_URI = "git://github.com/NVIDIA/cper-logger;protocol=https;branch=develop"
SRCREV = "5e915a885369312dcc87123dbd4fce8e707ab809"

PV = "1.0+git${SRCPV}"

SYSTEMD_SERVICE:${PN} = "xyz.openbmc_project.CPERLogger.service"

S = "${WORKDIR}/git"

inherit pkgconfig systemd meson

PACKAGECONFIG ??= ""

EXTRA_OEMESON = " \
    -Dtests=${@bb.utils.contains('PTEST_ENABLED', '1', 'enabled', 'disabled', d)} \
"

do_install_ptest() {
    install -d ${D}${PTEST_PATH}/test
    cp -rf ${B}/*_test ${D}${PTEST_PATH}/test/
}
