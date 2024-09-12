FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://mrd_PlatformEnvironmentMetrics.json \
                   file://mrd_MemoryMetrics.json \
                   file://mrd_ProcessorMetrics.json \
                   file://mrd_ProcessorGPMMetrics.json \
                   file://mrd_ProcessorPortMetrics.json \
                   file://mrd_ProcessorPortGPMMetrics.json \
                   file://mrd_CpuProcessorMetrics.json \
                 "

FILES:${PN}:append = " ${datadir}/${PN}/mrd_PlatformEnvironmentMetrics.json \
                       ${datadir}/${PN}/mrd_MemoryMetrics.json \
                       ${datadir}/${PN}/mrd_ProcessorMetrics.json \
                       ${datadir}/${PN}/mrd_ProcessorGPMMetrics.json \
                       ${datadir}/${PN}/mrd_ProcessorPortMetrics.json \
                       ${datadir}/${PN}/mrd_ProcessorPortGPMMetrics.json \
                       ${datadir}/${PN}/mrd_CpuProcessorMetrics.json \
                     "
                     
do_install:append() {
    install -d ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_PlatformEnvironmentMetrics.json ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_MemoryMetrics.json ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_ProcessorMetrics.json ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_ProcessorGPMMetrics.json ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_ProcessorPortMetrics.json ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_ProcessorPortGPMMetrics.json ${D}${datadir}/${PN}/
    install -m 0644 ${WORKDIR}/mrd_CpuProcessorMetrics.json ${D}${datadir}/${PN}/
}
