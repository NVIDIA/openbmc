FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://BMC.json \
                   file://Processor_Module.json \
                   file://HMC_FRU.json \
                   file://HMC_C2G2.json \
                   file://HMC_C2G4.json \
                   file://HMC_C2G4_GB300.json \
                   file://HMC_SAT.json \
                   file://Cable_Backplane_Cartridge.json \
                   file://PCIe_Cards.json \
                   file://i2cPcieMapping_CX7.json \
                   file://i2cPcieMapping_CX8.json \
                   file://fru-service.conf \
                   file://blacklist.json \
                   file://PDB_NVIDIA.json \
                   file://PDB_Quanta.json \
                   file://NVMe_Drive_CX7.json \
                   file://NVMe_Drive_CX8.json \
                   file://IO_Board_CX7.json \
                   file://IO_Board_CX8.json \
                   file://FIO_Board.json \
                   file://DCSCM_FIO_Board.json \
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
                   file://gb200nvl_mctp_bmc_target_configuration.json \
                   "

#Runtime dependency on fru-device defined in meta-prime

FILES:${PN}:append =  " /usr/lib/systemd/system/xyz.openbmc_project.FruDevice.service.d/fru-service.conf "
DEPENDS += "nvidia-tal"


do_install:append() {
     # Other files are already being removed in meta-prime
     install -m 0444 ${UNPACKDIR}/BMC.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Processor_Module.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_FRU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_C2G2.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_C2G4.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_C2G4_GB300.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/HMC_SAT.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Cable_Backplane_Cartridge.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/IO_Board_CX7.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/IO_Board_CX8.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/FIO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/DCSCM_FIO_Board.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/PCIe_Cards.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/PDB_NVIDIA.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/PDB_Quanta.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/NVMe_Drive_CX7.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/NVMe_Drive_CX8.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Chassis_1RU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/Chassis_2RU.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_gpio_recovery_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_rot_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/System.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_erot_recovery_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_static_inventory.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_erot_bmc_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_instance_mapping.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_cpld_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${UNPACKDIR}/gb200nvl_mctp_bmc_target_configuration.json ${D}/usr/share/entity-manager/configurations

     mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d
     install -m 0444 ${UNPACKDIR}/fru-service.conf  ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d/
     install -m 0444 ${UNPACKDIR}/blacklist.json ${D}/usr/share/entity-manager/

     install -m 0444 ${UNPACKDIR}/i2cPcieMapping_CX7.json ${D}/usr/share/entity-manager
     install -m 0444 ${UNPACKDIR}/i2cPcieMapping_CX8.json ${D}/usr/share/entity-manager

     # Create symbolic link from /usr/share/entity-manager/i2cPcieMapping.json to /etc/entity-manager/i2cPcieMapping.json
     ln -sf /etc/default/entity-manager/i2cPcieMapping.json  ${D}${datadir}/entity-manager/i2cPcieMapping.json
}
