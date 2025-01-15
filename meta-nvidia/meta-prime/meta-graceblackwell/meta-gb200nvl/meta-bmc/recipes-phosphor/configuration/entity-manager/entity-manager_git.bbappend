FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://GB200NVL_DCSCM.json \
                   file://Processor_Module.json \
                   file://HMC_FRU.json \
                   file://HMC_C2G2.json \
                   file://HMC_C2G4.json \
                   file://Cable_Backplane_Cartridge.json \
                   file://PCIe_Cards.json \
                   file://i2cPcieMapping.json \
                   file://fru-service.conf \
                   file://blacklist.json \
                   file://PDB_NVIDIA.json \
                   file://PDB_Quanta.json \
                   file://NVMe_Drive.json \
                   file://IO_Board.json \
                   file://FIO_Board.json \
                   file://Chassis_1RU.json \
                   file://Chassis_2RU.json \
                   file://gb200nvl_gpio_recovery_configuration.json \
                   file://gb200nvl_rot_chassis.json \
                   file://System.json \
                   file://gb200nvl_erot_recovery_configuration.json \
                   file://gb200nvl_static_inventory.json \
                   file://gb200nvl_erot_bmc_chassis.json \
                   file://gb200nvl_instance_mapping.json \
                   file://gb200nvl_cpld_chassis.json \
                   "

#Runtime dependency on fru-device defined in meta-prime

FILES:${PN}:append =  " /usr/lib/systemd/system/xyz.openbmc_project.FruDevice.service.d/fru-service.conf "
DEPENDS += "nvidia-tal"


do_install:append() {
     # Other files are already being removed in meta-prime
     install -m 0444 ${WORKDIR}/GB200NVL_DCSCM.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Processor_Module.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/HMC_FRU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/HMC_C2G2.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/HMC_C2G4.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Cable_Backplane_Cartridge.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/IO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/FIO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/PCIe_Cards.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/i2cPcieMapping.json ${D}/usr/share/entity-manager/
     install -m 0444 ${WORKDIR}/PDB_NVIDIA.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/PDB_Quanta.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/NVMe_Drive.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Chassis_1RU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Chassis_2RU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_gpio_recovery_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_rot_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/System.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_erot_recovery_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_static_inventory.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_erot_bmc_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_instance_mapping.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_cpld_chassis.json ${D}/usr/share/entity-manager/configurations

     mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d
     install -m 0444 ${WORKDIR}/fru-service.conf  ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d/
     install -m 0444 ${WORKDIR}/blacklist.json ${D}/usr/share/entity-manager/
}
