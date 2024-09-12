SUMMARY = "NVIDIA HMC I2C Dump Util"
PR = "r1"
PV = "0.1"

LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = "file://i2c_dump_util.sh \
           file://execute_command.sh \
           file://_utils.sh \
           file://hex-to-bin.awk \
           file://tests/test_fail_scenarios.sh \
           file://tests/test_happy_path.sh \
           file://README.md \
          "

RDEPENDS:${PN} = "bash gawk"

do_install() {
    install -d ${D}/usr/share/i2c-dump-util
    install -m 0755 ${WORKDIR}/i2c_dump_util.sh ${D}/usr/share/i2c-dump-util/
    install -m 0755 ${WORKDIR}/execute_command.sh ${D}/usr/share/i2c-dump-util/
    install -m 0755 ${WORKDIR}/_utils.sh ${D}/usr/share/i2c-dump-util/
    install -m 0755 ${WORKDIR}/hex-to-bin.awk ${D}/usr/share/i2c-dump-util/
    install -m 0755 ${WORKDIR}/README.md ${D}/usr/share/i2c-dump-util/

    install -d ${D}/usr/share/i2c-dump-util/tests
    install -m 0755 ${WORKDIR}/tests/test_fail_scenarios.sh ${D}/usr/share/i2c-dump-util/tests/
    install -m 0755 ${WORKDIR}/tests/test_happy_path.sh  ${D}/usr/share/i2c-dump-util/tests/
}
