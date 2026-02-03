FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://axiado-gb300nvl-bmc-mt2.dts \
            file://axiado-gb300nvl-bmc-mts2.dts \
            file://mctp.scc \
            file://mctp.cfg \
            "

do_configure:append() {
    cp ${UNPACKDIR}/axiado-gb300nvl-bmc-mt2.dts ${S}/arch/arm64/boot/dts/axiado/
    cp ${UNPACKDIR}/axiado-gb300nvl-bmc-mts2.dts ${S}/arch/arm64/boot/dts/axiado/
}
