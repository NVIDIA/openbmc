FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://phosphor-ipmi-net@.service"

RMCPP_EXTRA:append = "eth1"
SYSTEMD_SERVICE:${PN}:append = " \
        ${PN}@${RMCPP_EXTRA}.service \
        ${PN}@${RMCPP_EXTRA}.socket \
        "

SYSTEMD_SERVICE:${PN}:append:gb200nvl-bmc-ut3 = " \
        ${PN}@ut3usb0.service \
        ${PN}@ut3usb0.socket "

do_install:append(){
	rm ${D}${systemd_system_unitdir}/phosphor-ipmi-net@.service

	install -m 0644 ${WORKDIR}/phosphor-ipmi-net@.service  ${D}${systemd_system_unitdir}/phosphor-ipmi-net@.service
}
