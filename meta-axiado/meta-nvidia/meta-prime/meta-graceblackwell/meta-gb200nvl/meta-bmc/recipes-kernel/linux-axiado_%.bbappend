FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:gb200nvl-bmc-axiado = " file://axiado-gb200nvl-bmc-mt2.dts"
SRC_URI:append:gb200nvl-bmc-axiado = " file://axiado-gb200nvl-bmc-mts2.dts"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://axiado-scm3003-pega-gb200nvl-bmc.dts"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://nvidia-platform-devices.scc"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://nvidia-platform-devices.cfg"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://usb-net.scc"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://usb-net.cfg"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://usb-storage.scc"
SRC_URI:append:gb200nvl-bmc-axiado-github = " file://usb-storage.cfg"

do_configure:append:gb200nvl-bmc-axiado() {
    cp ${UNPACKDIR}/axiado-gb200nvl-bmc-mt2.dts ${S}/arch/arm64/boot/dts/axiado/
    cp ${UNPACKDIR}/axiado-gb200nvl-bmc-mts2.dts ${S}/arch/arm64/boot/dts/axiado/
}

do_configure:append:gb200nvl-bmc-axiado-github() {
    cp ${UNPACKDIR}/axiado-scm3003-pega-gb200nvl-bmc.dts ${S}/arch/arm64/boot/dts/axiado/
}
