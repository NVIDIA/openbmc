FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/cpld_config_cx7.json \
                   file://files/cpld_config_cx8.json \
                   file://files/powermanager.json \
                   file://files/cpldi2ccmd.sh \
                   file://files/nvidia-cpld.service \
"

EXTRA_OEMESON:append = " \
                         -Dplatform_fw_prefix="FW_" \
"

EXTRA_OEMESON:append = " -Dmodule_num=1 \
                         -Ddragon_chassis_cpld=enabled \
"
DEPENDS:append = " libgpiod "

do_install:append() {
        install -D ${WORKDIR}/files/cpld_config_cx7.json ${D}${datadir}/${PN}/cpld_config_cx7.json
        install -D ${WORKDIR}/files/cpld_config_cx8.json ${D}${datadir}/${PN}/cpld_config_cx8.json
        install -m 0644 ${WORKDIR}/files/powermanager.json ${D}${datadir}/nvidia-power-manager/
        install -D ${WORKDIR}/files/cpldi2ccmd.sh ${D}${bindir}/cpldi2ccmd.sh
        install -D ${WORKDIR}/files/nvidia-cpld.service ${D}${base_libdir}/systemd/system/nvidia-cpld.service

        # Create symbolic link from /usr/share/nvidia-power-manager/cpld_config.json to /etc/defaults/cpldmanager/cpld_config.json
        ln -sf /etc/default/cpldmanager/cpld_config.json ${D}${datadir}/nvidia-power-manager/cpld_config.json
}
