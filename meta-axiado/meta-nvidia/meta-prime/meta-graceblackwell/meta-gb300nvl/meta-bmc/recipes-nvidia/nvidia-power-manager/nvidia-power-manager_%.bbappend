FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

DEPENDS += "libgpiod"

SRC_URI += "file://cpld_config.json \
            file://powermanager.json \
            file://cpldi2ccmd.sh \
            file://nvidia-cpld.service \
	    "

# TODO: have to verify the following config on GB300NVL
EXTRA_OEMESON += "-Dplatform_fw_prefix="FW_" \
                  -Dmodule_num=1 \
		  -Ddragon_chassis_cpld=enabled \
		  "

do_install:append() {
        install -d ${D}${datadir}/nvidia-power-manager
        install -m 0644 ${UNPACKDIR}/cpld_config.json ${D}${datadir}/nvidia-power-manager/
        install -m 0644 ${UNPACKDIR}/powermanager.json ${D}${datadir}/nvidia-power-manager/
        install -D ${UNPACKDIR}/cpldi2ccmd.sh ${D}${bindir}/cpldi2ccmd.sh
        install -D ${UNPACKDIR}/nvidia-cpld.service ${D}${base_libdir}/systemd/system/nvidia-cpld.service
}
