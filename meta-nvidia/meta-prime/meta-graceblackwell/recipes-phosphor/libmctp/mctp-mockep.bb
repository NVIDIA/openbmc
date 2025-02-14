SUMMARY = "MCTP Mockup Endpoint services"
DESCRIPTION = "MCTP Mockup Endpoint services"
PR = "r1"
PV = "1.0+git${SRCPV}"

HOMEPAGE = "https://github.com/openbmc/libmctp"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=0d30807bb7a4f16d36e96b78f9ed8fae"

inherit systemd
inherit meson pkgconfig
inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

DEPENDS += "systemd \
            json-c \
            i2c-tools \
           "

SRC_URI = "git://github.com/NVIDIA/libmctp;protocol=https;branch=develop \
            file://mctp-mockep-demux.service \
            file://mctp-mockep-ctrl.service"

SRCREV = "16fc1691f89f3e9f5eaf3026c89b2e60235e837b"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON += " -Denable-mockup-endpoint=enabled"
EXTRA_OEMESON += " -Ddefault_library=static"

SYSTEMD_AUTO_ENABLE:${PN} = "disable"
SYSTEMD_SERVICE:${PN} = "mctp-mockep-demux.service \                     
                         mctp-mockep-ctrl.service \
                        "

do_install:append() {
    install -d ${D}${nonarch_base_libdir}/systemd/system
    install -m 0644 ${WORKDIR}/mctp-mockep-demux.service ${D}${nonarch_base_libdir}/systemd/system
    install -m 0644 ${WORKDIR}/mctp-mockep-ctrl.service ${D}${nonarch_base_libdir}/systemd/system

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket

    rm -f ${D}${base_bindir}/mctp-list-eps
    rm -f ${D}${base_bindir}/mctp-pcie-ctrl
    rm -f ${D}${base_bindir}/mctp-spi-ctrl
    rm -f ${D}${base_bindir}/mctp-usb-ctrl
    rm -f ${D}${base_bindir}/mctp-vdm-util

    mv ${D}${base_bindir}/mctp-ctrl ${D}${base_bindir}/mctp-mockep-ctrl
    mv ${D}${base_bindir}/mctp-demux-daemon ${D}${base_bindir}/mctp-mockep-demux
}

S = "${WORKDIR}/git"
