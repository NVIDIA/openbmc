FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://oob_cfg.json \
                   file://0001-WAR-for-BMC-WDT2-issue.patch \
                   "

# Remove the config files loaded in the main recipe and just install ours
do_install:append() {
    rm ${D}${datadir}/gpuoob/*.json
    install -m 0644 ${WORKDIR}/oob_cfg.json ${D}${datadir}/gpuoob/
}
