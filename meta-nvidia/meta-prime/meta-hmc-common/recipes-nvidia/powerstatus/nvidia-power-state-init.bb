SUMMARY = "NVIDIA POWER State Init service for HMC"
PR = "r1"
PV = "0.1"

# FIXME: once having the correct license info for upstream
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS += "systemd"

S = "${WORKDIR}"

FILESEXTRAPATHS:append := ":${THISDIR}/files"

SYSDSVC = "nvidia-power-state-init.service"
SRC_URI = "file://${SYSDSVC} \
          "

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "${SYSDSVC}"
SYSTEMD_LINK_${PN} += "${@compose_list(d, 'FMT', 'PWRSTS_SERVICE')}"
