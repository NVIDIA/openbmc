FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/cpld_config.json \
                   file://files/powermanager.json \
"

EXTRA_OEMESON:append = " \
                         -Dplatform_fw_prefix="FW_" \
"

do_install:append() {
        install -D ${WORKDIR}/files/cpld_config.json ${D}${datadir}/${PN}/cpld_config.json
        install -m 0644 ${WORKDIR}/files/powermanager.json ${D}${datadir}/nvidia-power-manager/
}
