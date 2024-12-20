SUMMARY = "NVIDIA NVME CPLD Probe Service"
PR = "r1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd
DEPENDS = "systemd"
RDEPENDS:${PN} = "bash nvidia-nvme-cpld"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " file://nvme_lib.sh \
            file://nvme_cpld_probe.sh \
            file://nvme_cpld_remove.sh \
            file://nvidia-nvmecpld-remove.service \
          "

SYSTEMD_SERVICE:${PN} = "nvidia-nvmecpld-remove.service "

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/nvme_lib.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/nvme_cpld_probe.sh ${D}/${bindir}/
    install -m 0755 ${WORKDIR}/nvme_cpld_remove.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/nvidia-nvmecpld-remove.service ${D}${base_libdir}/systemd/system/
}
