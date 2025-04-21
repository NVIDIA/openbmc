SUMMARY = "NVIDIA Management Controller library"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

RDEPENDS:${PN} = "bash nvidia-event-logs"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " \
	file://gpio_check.sh \
	file://gpio_tools.sh \
	file://filesystem_check.sh \
	file://mc_lib.sh \
	file://system_state_files.sh \
	file://banner_art.txt \
	"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${S}/gpio_check.sh ${D}/${bindir}/gpio_check.sh
    install -m 0755 ${S}/gpio_tools.sh ${D}/${bindir}/gpio_tools.sh
    install -m 0755 ${S}/filesystem_check.sh ${D}/${bindir}/filesystem_check.sh
    install -m 0755 ${S}/mc_lib.sh ${D}/${bindir}/mc_lib.sh
    install -m 0755 ${S}/system_state_files.sh ${D}/${bindir}/system_state_files.sh
    install -m 0755 ${S}/banner_art.txt ${D}/${bindir}/banner_art.txt
}

