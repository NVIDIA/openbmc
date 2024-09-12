FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://HMC.json \
                   file://Grace_Bianca_Superchip.json \
                   file://blacklist.json \
                   file://gb200nvl_fpga_chassis.json \
                   file://gb200nvl_gpu_chassis.json \
                   file://gb200nvl_cpld_chassis.json \
                   file://gb200nvl_rot_chassis.json \
                   file://gb200nvl_processor_systems.json \
                   file://gb200nvl_memory_systems.json \
                   file://gb200nvl_static_inventory.json \
                   file://gb200nvl_nvlink_topology.json \
                   file://gb200nvl_gpu_configuration.json \
                   file://gb200nvl_erot_configuration.json \
                   file://gb200nvl_gpio_configuration.json \
                   file://gb200nvl_instance_mapping.json \ 
                 "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json

     install -m 0444 ${WORKDIR}/HMC.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/Grace_Bianca_Superchip.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/blacklist.json ${D}/usr/share/entity-manager/

     install -m 0444 ${WORKDIR}/gb200nvl_fpga_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_gpu_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_cpld_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_rot_chassis.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_processor_systems.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_memory_systems.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_static_inventory.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_nvlink_topology.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_gpu_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_erot_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_gpio_configuration.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/gb200nvl_instance_mapping.json ${D}/usr/share/entity-manager/configurations
}
