SUMMARY = "NVIDIA HMC systemd-conf for: systemd-coredump space limitation"
PR = "r1"
PV = "0.1"

# FIXME: when get correct license info
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

FILEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
            file://systemd-coredump.conf \
           "

FILES:${PN} += " \
    ${sysconfdir}/systemd/coredump.conf.d/systemd-coredump.conf \
"

do_install:append() {
    install -d ${D}${sysconfdir}/systemd/coredump.conf.d
    install -m 0644 ${WORKDIR}/systemd-coredump.conf ${D}${sysconfdir}/systemd/coredump.conf.d
}
