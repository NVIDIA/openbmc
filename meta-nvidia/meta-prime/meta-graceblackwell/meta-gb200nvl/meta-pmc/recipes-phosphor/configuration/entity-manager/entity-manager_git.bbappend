FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://Chassis_PowerShelf.json \
                   "

#Runtime dependency on fru-device defined in meta-prime

DEPENDS += "nvidia-tal"

RDEPENDS:${PN}:append = " bash"

do_install:append() {
     # Other files are already being removed in meta-prime
     install -m 0444 ${WORKDIR}/Chassis_PowerShelf.json ${D}/usr/share/entity-manager/configurations
}
