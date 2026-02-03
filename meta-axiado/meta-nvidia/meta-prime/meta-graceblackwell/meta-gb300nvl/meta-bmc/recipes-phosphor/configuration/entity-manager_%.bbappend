FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://Cable_Backplane_Cartridge.json \
            file://Chassis_1RU.json \
            file://FIO_Board.json \
            file://GB300NVL_DCSCM.json \
            file://HMC_C2G4.json \
            file://HMC_FRU.json \
            file://IO_Board.json \
            file://NVMe_Drive.json \
            file://PCIe_Cards.json \
            file://PDB_NVIDIA.json \
            file://Processor_Module.json \
            file://System.json \
            file://blacklist.json \
            file://fru-service.conf \
            file://gb300nvl_cpld_chassis.json \
            file://gb300nvl_gpio_recovery_configuration.json \
            file://gb300nvl_instance_mapping.json \
            file://i2cPcieMapping.json \
            "

#Runtime dependency on fru-device defined in meta-prime

FILES:${PN}:append =  " /usr/lib/systemd/system/xyz.openbmc_project.FruDevice.service.d/fru-service.conf"
DEPENDS += "nvidia-tal"

do_install:append() {
     # Other files are already being removed in meta-prime
     install -m 0444 ${UNPACKDIR}/Cable_Backplane_Cartridge.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Chassis_1RU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/FIO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/GB300NVL_DCSCM.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_C2G4.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_FRU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/IO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/NVMe_Drive.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/PCIe_Cards.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/PDB_NVIDIA.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Processor_Module.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/System.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/blacklist.json ${D}/usr/share/entity-manager/
     install -m 0444 ${UNPACKDIR}/gb300nvl_cpld_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb300nvl_gpio_recovery_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb300nvl_instance_mapping.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/i2cPcieMapping.json ${D}/usr/share/entity-manager

     mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d
     install -m 0444 ${UNPACKDIR}/fru-service.conf  ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d/
}
