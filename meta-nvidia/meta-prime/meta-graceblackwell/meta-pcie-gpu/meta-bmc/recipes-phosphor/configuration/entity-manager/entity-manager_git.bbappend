FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://fru-service.conf \
                   file://blacklist.json \
                   file://pcie_gpu_nsm_gpu_static_inventory_gpu.json \
                   file://pcie_gpu_instance_mapping.json \
                   file://pcie_gpu_systems_processor.json \
                   file://pcie_gpu_nsm_gpu_chassis.json \
                   "

#Runtime dependency on fru-device defined in meta-prime

FILES:${PN}:append =  " /usr/lib/systemd/system/xyz.openbmc_project.FruDevice.service.d/fru-service.conf "
DEPENDS += "nvidia-tal"


do_install:append() {
     # Other files are already being removed in meta-prime

     install -m 0444 ${WORKDIR}/pcie_gpu_nsm_gpu_static_inventory_gpu.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/pcie_gpu_instance_mapping.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/pcie_gpu_systems_processor.json ${D}/usr/share/entity-manager/configurations
     install -m 0444 ${WORKDIR}/pcie_gpu_nsm_gpu_chassis.json ${D}/usr/share/entity-manager/configurations

     mkdir -p ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d
     install -m 0444 ${WORKDIR}/fru-service.conf  ${D}${base_libdir}/systemd/system/xyz.openbmc_project.FruDevice.service.d/
     install -m 0444 ${WORKDIR}/blacklist.json ${D}/usr/share/entity-manager/
}
