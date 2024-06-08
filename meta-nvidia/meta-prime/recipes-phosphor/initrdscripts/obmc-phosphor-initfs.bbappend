FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += "file://reserved-list \
            file://gb200nvl-bmc-ut3/obmc-init.sh"

do_install:append() {
    install -m 0644 ${WORKDIR}/reserved-list ${D}/reserved-list
}

do_install:append:gb200nvl-bmc-ut3() {
    install -m 0755 ${WORKDIR}/gb200nvl-bmc-ut3/obmc-init.sh ${D}/init
}

FILES:${PN} += " /reserved-list"
