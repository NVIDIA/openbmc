FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# TODO: Have to verify the following config on GB300NVL
EXTRA_OEMESON += "-Dplatform-system-id=Baseboard_0"

SRC_URI += "file://shm_mapping.json \
            file://shm_namespace_config.json \
            "

do_install:append() {
    install -m 0644 ${UNPACKDIR}/shm_mapping.json ${D}${datadir}/nvshmem
    install -m 0644 ${UNPACKDIR}/shm_namespace_config.json ${D}${datadir}/nvshmem
}
