SUMMARY = "NVIDIA GPU Manager Daemon"
DESCRIPTION = "NVIDIA GPU Manager Daemon"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/bmc/nvidia-gpu-manager"
PR = "r1"
PV = "0.1+git${SRCPV}"

# Need correct license info here before upstream.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit autotools pkgconfig
inherit obmc-phosphor-ipmiprovider-symlink
inherit systemd

DEPENDS += "autoconf-archive-native"
DEPENDS += "sdbusplus"
DEPENDS += "phosphor-logging"
DEPENDS += "phosphor-ipmi-host"
DEPENDS += "nlohmann-json"
DEPENDS += "systemd"
DEPENDS += "nvidia-gpuoob"
DEPENDS += "i2c-tools"
DEPENDS += "nvidia-tal"

EXTRA_OECONF += "--enable-sensor-prefix"
#EXTRA_OECONF += "--enable-shm_sensor_aggregator"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI = "git://github.com/NVIDIA/nvidia-gpu-manager;protocol=https;branch=develop"
SRCREV = "130289b236ea98fab707fa53739e02f39edb87d1"
S = "${WORKDIR}/git"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:dgx = " file://dgx/fpga_ready_sense.sh \
                       file://dgx/nvidia-gpu-manager-dgx.conf"
SRC_URI:append:dgx-a100-dp = " file://dgx-a100-dp/fpga_ready_sense.sh \
                               file://dgx-a100-dp/nvidia-gpu-manager-dgx.conf"
SRC_URI:append:e4830 = " file://dgx-a100-dp/fpga_ready_sense.sh \
                         file://dgx-a100-dp/nvidia-gpu-manager-dgx.conf"
SRC_URI:append:e4830-bmc = " file://e4830-bmc/fpga_ready_sense.sh \
                             file://hgx/nvidia-gpu-manager-hgx.conf"
SRC_URI:append:evb = " file://dgx-a100-dp/fpga_ready_sense.sh \
                       file://dgx-a100-dp/nvidia-gpu-manager-dgx.conf"
SRC_URI:append:hgx = " file://hgx/nvidia-gpu-manager-hgx.conf \
			file://hgx/eeprom-write.sh \
			file://hgx/fru_manager.json"
SRC_URI:append:e4830-hmc = " file://e4830-hmc/fpga_ready_sense.sh \
                             file://hgx/nvidia-gpu-manager-hgx.conf"
SRC_URI:append:hgxb = " file://hgxb/nvidia-gpu-manager-hgx.conf \
			file://hgxb/eeprom-write.sh \
			file://hgxb/fru_manager.json"
SRC_URI:append:e4830-hgxb-hmc = " file://e4830-hgxb-hmc/fpga_ready_sense.sh \
                             file://hgxb/nvidia-gpu-manager-hgx.conf"
SRC_URI:append:e4830-hgxb-bmc = " file://e4830-hgxb-bmc/fpga_ready_sense.sh \
                             file://hgxb/nvidia-gpu-manager-hgx.conf"
SRC_URI:append:hgxb300 = " file://hgxb300/nvidia-gpu-manager-hgx.conf \
			file://hgxb300/eeprom-write.sh \
			file://hgxb300/fru_manager.json"
SRC_URI:append:evb-ast2600-hgxb300 = " file://evb-ast2600-hgxb300/nvidia-gpu-manager-hgx.conf \
			file://evb-ast2600-hgxb300/eeprom-write.sh \
			file://evb-ast2600-hgxb300/fru_manager.json"

SRC_URI:append = " file://device.json"
SRC_URI:append = " file://ist-config.json"


SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "nvidia-gpu-manager.service"
LIBRARY_NAMES = "libnvoemcmds.so"

# recovery service
SYSTEMD_SERVICE:${PN} += "nvidia-gpu-oob-recovery.service"

# fpga ready handling
SYSTEMD_SERVICE:${PN} += "nvidia-fpga-ready.target \
                          nvidia-fpga-ready.service \
                          nvidia-pcie-link-mgnt.service \
                          nvidia-fpga-notready.target \
                          nvidia-fpga-notready.service \
                        nvidia-fru-manager.service"

#IST Mode handling
SYSTEMD_SERVICE:${PN} += "nvidia-ist-mode-manager.service"

SYSTEMD_SERVICE:${PN}:append:dgx = " nvidia-fpga-ready-handler-bind.service \
                                     nvidia-fpga-ready-handler-unbind.service"

SYSTEMD_SERVICE:${PN}:append:dgx-a100-dp = " nvidia-fpga-ready-handler-bind.service \
                                             nvidia-fpga-ready-handler-unbind.service"

SYSTEMD_SERVICE:${PN}:append:e4830 = " nvidia-fpga-ready-handler-bind.service \
                                       nvidia-fpga-ready-handler-unbind.service"

SYSTEMD_SERVICE:${PN}:append:evb = " nvidia-fpga-ready-handler-bind.service \
                                     nvidia-fpga-ready-handler-unbind.service"

SYSTEMD_SERVICE:${PN}:append:e4830-bmc = " nvidia-fpga-ready-handler.service"

SYSTEMD_SERVICE:${PN}:append:e4830-hmc = " nvidia-fpga-ready-handler.service"


HOSTIPMI_PROVIDER_LIBRARY += " ${LIBRARY_NAMES}"
NETIPMI_PROVIDER_LIBRARY += " ${LIBRARY_NAMES}"

ERR_HANDLER_JSON = "errhandler.json"
ERR_HANDLER_JSON_SRC = "${S}/recovery_sw_module/configs/hgx/${ERR_HANDLER_JSON}"

FILES:${PN}:append = " ${bindir}/gpumgrd"
FILES:${PN}:append = " ${bindir}/recovery_sw_module"
FILES:${PN}:append = " ${bindir}/fpga_ready_handler"
FILES:${PN}:append = " ${bindir}/ist_mode_manager"
FILES:${PN}:append = " ${datadir}/gpuoob/device.json"
FILES:${PN}:append = " ${datadir}/nvidia-ist-manager/ist-config.json"
FILES:${PN}:append = " ${datadir}/gpuoob/${ERR_HANDLER_JSON}"
FILES:${PN}:append = " ${libdir}/ipmid-providers/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/host-ipmid/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/net-ipmid/lib*${SOLIBS}"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-*.service"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-*.target"
FILES:${PN}:append = " ${datadir}/nvidia-fru-manager/"
FILES:${PN}:append = " ${datadir}/nvidia-fru-manager/fru_manager.json"
FILES:${PN}-dev:append = " ${libdir}/ipmid-providers/lib*${SOLIBSDEV}"
FILES:${PN}-dev:append = " ${libdir}/ipmid-providers/*.la"
FILES:${PN}-dev:append = " ${includedir}/*.hpp"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-gpu-manager.service.d/*"


do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -d ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d
    install -m 0664 ${S}/systemd/nvidia-fpga-notready* ${D}${systemd_system_unitdir}/
    install -m 0664 ${S}/systemd/nvidia-fpga-ready.* ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/systemd/nvidia-gpu-manager.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/systemd/nvidia-gpu-oob-recovery.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/systemd/nvidia-pcie-link-mgnt.service ${D}${systemd_system_unitdir}/
    install -m 0644 ${S}/systemd/nvidia-fru-manager.service ${D}${systemd_system_unitdir}/
    install -d ${D}${datadir}/nvidia-ist-manager
    install -m 0644 ${WORKDIR}/ist-config.json ${D}${datadir}/nvidia-ist-manager/
    install -m 0644 ${S}/systemd/nvidia-ist-mode-manager.service ${D}${systemd_system_unitdir}/
    install -d ${D}${datadir}/gpuoob
    install -m 0644 ${WORKDIR}/device.json ${D}${datadir}/gpuoob/
    install -m 0644 ${ERR_HANDLER_JSON_SRC} ${D}${datadir}/gpuoob/
}

do_install:append:dgx() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-bind.service ${D}${systemd_system_unitdir}/
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-unbind.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/dgx/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/dgx/nvidia-gpu-manager-dgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:dgx-a100-dp() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-bind.service ${D}${systemd_system_unitdir}/
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-unbind.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/dgx-a100-dp/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/dgx-a100-dp/nvidia-gpu-manager-dgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:e4830() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-bind.service ${D}${systemd_system_unitdir}/
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-unbind.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/dgx-a100-dp/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/dgx-a100-dp/nvidia-gpu-manager-dgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:e4830-bmc() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/e4830-bmc/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/hgx/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:evb() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-bind.service ${D}${systemd_system_unitdir}/
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler-unbind.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/dgx-a100-dp/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/dgx-a100-dp/nvidia-gpu-manager-dgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:hgx() {
    install -d ${D}/${bindir}
    install -m 0644 ${WORKDIR}/hgx/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
        mkdir ${D}${datadir}/nvidia-fru-manager/
    install -D ${WORKDIR}/hgx/fru_manager.json ${D}${datadir}/nvidia-fru-manager/
    install -m 0755   ${WORKDIR}/hgx/eeprom-write.sh ${D}/${bindir}/
}
do_install:append:e4830-hmc() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/e4830-hmc/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/hgx/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:e4830-hgxb-hmc() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/e4830-hgxb-hmc/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/hgxb/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:e4830-hgxb-bmc() {
    install -d ${D}/${bindir}
    install -m 0664 ${S}/systemd/nvidia-fpga-ready-handler.service ${D}${systemd_system_unitdir}/
    install -m 0755 ${WORKDIR}/e4830-hgxb-bmc/fpga_ready_sense.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/hgxb/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
}
do_install:append:hgxb() {
    install -d ${D}/${bindir}
    install -m 0644 ${WORKDIR}/hgxb/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
	mkdir ${D}${datadir}/nvidia-fru-manager/
    install -D ${WORKDIR}/hgxb/fru_manager.json ${D}${datadir}/nvidia-fru-manager/
    install -m 0755   ${WORKDIR}/hgxb/eeprom-write.sh ${D}/${bindir}/
}
do_install:append:hgxb300() {
    install -d ${D}/${bindir}
    install -m 0644 ${WORKDIR}/hgxb300/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
	mkdir ${D}${datadir}/nvidia-fru-manager/
    install -D ${WORKDIR}/hgxb300/fru_manager.json ${D}${datadir}/nvidia-fru-manager/
    install -m 0755   ${WORKDIR}/hgxb300/eeprom-write.sh ${D}/${bindir}/
}

do_install:append:evb-ast2600-hgxb300() {
    install -d ${D}/${bindir}
    install -m 0644 ${WORKDIR}/evb-ast2600-hgxb300/nvidia-gpu-manager-hgx.conf \
                    ${D}${systemd_system_unitdir}/nvidia-gpu-manager.service.d/
	mkdir ${D}${datadir}/nvidia-fru-manager/
    install -D ${WORKDIR}/evb-ast2600-hgxb300/fru_manager.json ${D}${datadir}/nvidia-fru-manager/
    install -m 0755   ${WORKDIR}/evb-ast2600-hgxb300/eeprom-write.sh ${D}/${bindir}/
}

