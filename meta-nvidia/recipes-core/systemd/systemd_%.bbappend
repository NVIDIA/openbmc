PACKAGECONFIG:append = " kmod"
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append += "file://systemd-journald-override.conf"
FILES:${PN}:append = "${systemd_unitdir}/journald.conf.d/systemd-journald-override.conf"
do_install:append() {
    install -m 644 -D ${WORKDIR}/systemd-journald-override.conf ${D}${systemd_system_unitdir}/systemd-journald.service.d/systemd-journald-override.conf
}
