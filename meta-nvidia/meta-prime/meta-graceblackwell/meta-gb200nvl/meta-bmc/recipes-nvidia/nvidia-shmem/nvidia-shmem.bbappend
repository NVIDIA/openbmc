XTRA_OEMESON:append = " -Dplatform-system-id=Baseboard_0"

# Add platform specific shared memory mapping file
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://shm_mapping.json \
                   file://shm_namespace_config.json \
                 "

do_install:append() {
    install -m 0644 ${WORKDIR}/shm_mapping.json ${D}${datadir}/nvshmem
    install -m 0644 ${WORKDIR}/shm_namespace_config.json ${D}${datadir}/nvshmem
}
