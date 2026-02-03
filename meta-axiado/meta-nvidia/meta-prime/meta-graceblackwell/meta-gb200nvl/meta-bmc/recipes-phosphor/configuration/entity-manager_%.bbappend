FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://Carlo_E1.s_BP.json \
            file://Carlo_IPEX.json \
            file://Carlo_NIC.json \
            file://Carlo_OSFP.json \
            file://Chassis_Carlo_1RU.json \
            file://PDB_PEGA.json \
            "

do_install:append() {
     install -m 0444 ${UNPACKDIR}/Carlo_E1.s_BP.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Carlo_IPEX.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Carlo_NIC.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Carlo_OSFP.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Chassis_Carlo_1RU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/PDB_PEGA.json ${D}/usr/share/entity-manager/configurations
}
