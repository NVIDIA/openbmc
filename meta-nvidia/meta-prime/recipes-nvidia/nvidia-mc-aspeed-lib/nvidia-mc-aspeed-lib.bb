SUMMARY = "NVIDIA ASPEED Management Controller library"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " \
	file://gpio_pins.sh \
	"

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${S}/gpio_pins.sh ${D}/${bindir}/gpio_pins.sh
}
