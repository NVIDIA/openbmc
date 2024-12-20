FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://common/Grace_Bianca_Superchip.json \
                   file://common/HMC.json \
                   file://common/System.json \
                   file://common/blacklist.json \
                   file://common/gb200nvl_cpld_chassis.json \
                   file://common/gb200nvl_erot_bmc_chassis.json \
                   file://common/gb200nvl_erot_chassis.json \
                   file://common/gb200nvl_erot_configuration.json \
                   file://common/gb200nvl_erot_fpga_chassis.json \
                   file://common/gb200nvl_gpio_configuration.json \
                   file://common/gb200nvl_memory_systems_cpu.json \
                   file://common/gb200nvl_processor_systems_cpu.json \
                   file://common/gb200nvl_static_inventory.json \
                   file://c1g1/gb200nvl_fpga_chassis_ariel.json \
                   file://c1g1/gb200nvl_gpu_chassis_ariel.json \
                   file://c1g1/gb200nvl_gpu_configuration_ariel.json \
                   file://c1g1/gb200nvl_instance_mapping_ariel.json \
                   file://c1g1/gb200nvl_irot_gpu_chassis_ariel.json \
                   file://c1g1/gb200nvl_memory_systems_gpu_ariel.json \
                   file://c1g1/gb200nvl_nvlink_topology_ariel.json \
                   file://c1g1/gb200nvl_processor_systems_gpu_ariel.json \
                   file://c1g1/gb200nvl_static_inventory_gpu_ariel.json \
                   file://c1g2/gb200nvl_fpga_chassis_bianca.json \
                   file://c1g2/gb200nvl_gpu_chassis_bianca.json \
                   file://c1g2/gb200nvl_gpu_configuration_bianca.json \
                   file://c1g2/gb200nvl_instance_mapping_bianca.json \
                   file://c1g2/gb200nvl_irot_gpu_chassis_bianca.json \
                   file://c1g2/gb200nvl_memory_systems_gpu_bianca.json \
                   file://c1g2/gb200nvl_nvlink_topology_bianca.json \
                   file://c1g2/gb200nvl_processor_systems_gpu_bianca.json \
                   file://c1g2/gb200nvl_static_inventory_gpu_bianca.json \
                 "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json

     install -m 0444 ${WORKDIR}/common/blacklist.json ${D}/usr/share/entity-manager/

     install -m 0444 ${WORKDIR}/common/Grace_Bianca_Superchip.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/HMC.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/System.json ${D}/usr/share/entity-manager/configurations

     install -m 0444 ${WORKDIR}/common/gb200nvl_cpld_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_erot_bmc_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_erot_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_erot_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_erot_fpga_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_gpio_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_memory_systems_cpu.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_processor_systems_cpu.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/common/gb200nvl_static_inventory.json ${D}/usr/share/entity-manager/configurations

     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_fpga_chassis_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_gpu_chassis_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_gpu_configuration_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_instance_mapping_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_irot_gpu_chassis_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_memory_systems_gpu_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_nvlink_topology_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_processor_systems_gpu_ariel.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g1/gb200nvl_static_inventory_gpu_ariel.json ${D}/usr/share/entity-manager/configurations

     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_fpga_chassis_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_gpu_chassis_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_gpu_configuration_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_instance_mapping_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_irot_gpu_chassis_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_memory_systems_gpu_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_nvlink_topology_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_processor_systems_gpu_bianca.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/c1g2/gb200nvl_static_inventory_gpu_bianca.json ${D}/usr/share/entity-manager/configurations

}
