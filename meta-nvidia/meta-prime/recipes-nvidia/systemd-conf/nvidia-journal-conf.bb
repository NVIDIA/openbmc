SUMMARY = "NVIDIA journal conf for systemd services"

# We have added the persistent storage cap at the 30 MB due to size issue in /tmp will have to change the emmc-journal-storage.conf to required limit if /tmp increases.

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
