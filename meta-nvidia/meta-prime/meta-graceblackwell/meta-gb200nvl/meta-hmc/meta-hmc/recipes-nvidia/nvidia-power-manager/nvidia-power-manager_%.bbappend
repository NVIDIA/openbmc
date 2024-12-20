FILESEXTRAPATHS:prepend := "${THISDIR}:"

SYSTEMD_SERVICE:${PN}:remove = "nvidia-psu-monitor.service"

SRC_URI:append = " file://files/cpld_config.json \
                   file://files/cpldi2ccmd.sh \
"

EXTRA_OEMESON:append = " -Dplatform_prefix="HGX_" \
                         -Dplatform_fw_prefix="FW_" \
                         -Dmodule_num=1 \
"

do_install:append() {
        install -D ${WORKDIR}/files/cpld_config.json ${D}${datadir}/${PN}/cpld_config.json
        rm -f ${D}${nonarch_base_libdir}/systemd/system/nvidia-psu-monitor.service
        install -D ${WORKDIR}/files/cpldi2ccmd.sh ${D}${bindir}/cpldi2ccmd.sh
}
