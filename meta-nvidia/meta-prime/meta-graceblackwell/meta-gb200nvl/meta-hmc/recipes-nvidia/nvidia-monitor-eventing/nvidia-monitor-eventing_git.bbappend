FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://dat.json \
    file://dat_GB200.json \
    file://event_info.json \
    file://event_info_GB200.json \
    file://device_mctp_eid.csv \
    file://fpga_regtbl_platform.conf \
    "

RDEPENDS:${PN}:append = " bash"
RDEPENDS:${PN}:append = " nvidia-pcm"

do_install:append() {
    install -d ${D}${datadir}/mon_evt
    install -m 0644 ${WORKDIR}/dat.json ${D}${datadir}/mon_evt/
    install -m 0644 ${WORKDIR}/dat_GB200.json ${D}${datadir}/mon_evt/
    install -m 0644 ${WORKDIR}/event_info.json ${D}${datadir}/mon_evt/
    install -m 0644 ${WORKDIR}/event_info_GB200.json ${D}${datadir}/mon_evt/
    install -m 0644 ${WORKDIR}/device_mctp_eid.csv ${D}${datadir}/
    install -m 0644 ${WORKDIR}/fpga_regtbl_platform.conf ${D}${datadir}/


    sed -i "s|DEV_EID_PROFILE=\"device_mctp_eid.csv\"|DEV_EID_PROFILE=\"${datadir}/device_mctp_eid.csv\"|" ${D}${bindir}/mctp-vdm-util-wrapper
}


