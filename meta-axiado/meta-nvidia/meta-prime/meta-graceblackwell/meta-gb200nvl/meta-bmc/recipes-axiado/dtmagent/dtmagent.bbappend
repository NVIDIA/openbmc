FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://tcu_fan_script.sh"

do_install:append() {
    install -m 0755 ${UNPACKDIR}/tcu_fan_script.sh ${D}${bindir}/tcu_fan_script.sh
}

FILES:${PN} += "${bindir}/tcu_fan_script.sh"
