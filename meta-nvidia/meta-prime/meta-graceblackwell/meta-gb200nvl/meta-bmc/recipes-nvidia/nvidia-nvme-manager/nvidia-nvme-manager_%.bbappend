FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://nvidia-nvme-manager.service \
                 "

do_install:append() {
    install -d  ${D}${datadir}/nvidia-nvme-manager/
    install -m 0644 ${WORKDIR}/nvidia-nvme-manager.service  ${D}${nonarch_base_libdir}/systemd/system/
}
