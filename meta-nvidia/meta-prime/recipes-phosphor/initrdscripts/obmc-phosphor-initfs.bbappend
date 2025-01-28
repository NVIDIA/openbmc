FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += "file://reserved-list \
            file://gb200nvl-bmc-ut3/obmc-init.sh \
            file://gb200nvl-hmc/obmc-init.sh \
            file://gb300nvl-hmc/obmc-init.sh \
"

do_install:append() {
    install -m 0644 ${WORKDIR}/reserved-list ${D}/reserved-list
}

do_install:append:gb200nvl-bmc-ut3() {
    install -m 0755 ${WORKDIR}/gb200nvl-bmc-ut3/obmc-init.sh ${D}/init
}

do_install:append:gb200nvl-hmc() {
    install -m 0755 ${WORKDIR}/gb200nvl-hmc/obmc-init.sh ${D}/init
}

do_install:append:gb300nvl-hmc() {
    install -m 0755 ${WORKDIR}/gb300nvl-hmc/obmc-init.sh ${D}/init
}

FILES:${PN} += " /reserved-list"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', 'true', 'false', d)}; then
        bbwarn "erotless-bmc enabled. Modifying obmc-init.sh"
        sed -i '/echo "1e620000.spi" > \/sys\/bus\/platform\/drivers\/spi-aspeed-smc\/unbind/d' ${S}/obmc-init.sh
        sed -i '/echo "unbind aspeed spi flash driver"/d' ${S}/obmc-init.sh
    fi
}
