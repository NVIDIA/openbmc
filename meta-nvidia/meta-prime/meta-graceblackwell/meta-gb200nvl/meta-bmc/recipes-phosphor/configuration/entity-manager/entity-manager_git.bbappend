FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://GB200NVL_DCSCM.json \
                   file://Processor_Module.json \
                   file://HMC.json \
                   file://Cable_Backplane_Cartridge.json \
                   file://PCIe_Cards.json \
                   file://i2cPcieMapping.json \
                   file://fru-service.conf \
                   file://blacklist.json \
                   file://PDB.json \
                   file://NVMe_Drive.json \
                   file://IO_Board.json \
                   file://Chassis.json \
                   file://gb200nvl_gpio_recovery_configuration.json \
                   file://System.json \
                   "

#Runtime dependency on fru-device defined in meta-prime

FILES:${PN}:append =  " /usr/lib/systemd/system/xyz.openbmc_project.FruDevice.service.d/fru-service.conf "
DEPENDS += "nvidia-tal"


do_install:append() {
     # Other files are already being removed in meta-prime
     install -m 0444 ${WORKDIR}/GB200NVL_DCSCM.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Processor_Module.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/HMC.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Cable_Backplane_Cartridge.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/IO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/PCIe_Cards.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/i2cPcieMapping.json ${D}/usr/share/entity-manager/
     install -m 0444 ${WORKDIR}/PDB.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/NVMe_Drive.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_gpio_recovery_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/System.json ${D}/usr/share/entity-manager/configurations

     mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d
     install -m 0444 ${WORKDIR}/fru-service.conf  ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d/
     install -m 0444 ${WORKDIR}/blacklist.json ${D}/usr/share/entity-manager/
}
