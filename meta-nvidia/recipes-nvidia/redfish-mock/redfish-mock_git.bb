SUMMARY = "Redfish Mock"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/redfish"

SRC_URI = "git://git@gitlab-master.nvidia.com:12051/dgx/redfish;protocol=ssh;branch=generated-mock/umbriel"
SRCREV = "ee08ade49b2841419eea4f558fd411f984b252c1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

S = "${WORKDIR}/git"

FILES:${PN}:append = " ${datadir}/mock"
FILES:${PN}:append = " ${datadir}/mock/*"

do_install() {
    install -d ${D}${datadir}/mock
    cp -R ${S}/mockup/generated/nvidia-hgx-umbriel-baseboard/* ${D}${datadir}/mock/
}
