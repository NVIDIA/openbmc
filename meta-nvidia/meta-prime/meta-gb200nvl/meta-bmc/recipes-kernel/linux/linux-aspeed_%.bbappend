
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://gb200nvl-bmc.cfg \
                   file://aspeed-bmc-nvidia-gb200nvl-bmc.dts \
                   file://aspeed-bmc-nvidia-gb200nvl-bmc-ut3.dts \
                   file://nvidia-gb200nvl-bmc-core.dtsi"

do_configure:append() {
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-bmc.dts ${S}/arch/arm/boot/dts/
	cp ${WORKDIR}/aspeed-bmc-nvidia-gb200nvl-bmc-ut3.dts ${S}/arch/arm/boot/dts
	cp ${WORKDIR}/nvidia-gb200nvl-bmc-core.dtsi ${S}/arch/arm/boot/dts/
}
