SUMMARY = "NVIDIA journal conf for systemd services"
PR = "r1"
PV = "0.1"

# Added the SystemMaxUse in the journal conf to keep the journal persistent storage at 64MB this can be increased on the basis of the /tmp space availability.

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

FILEXTRAPATHS:prepend := "${THISDIR}/files:"


SRC_URI += " \
            file://nvidia-journal.conf \
           "

FILES:${PN} += " \
    ${sysconfdir}/systemd/journald.conf.d/nvidia-journal.conf  \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/journald.conf.d
    install -m 0644 ${WORKDIR}/nvidia-journal.conf ${D}${sysconfdir}/systemd/journald.conf.d
}
