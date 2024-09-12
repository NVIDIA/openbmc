FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://0001-meta-gb200-nvl-Patch-for-Hotplug-detect-DP-signal.patch \
                   file://ast2600-gb200nvl-bmc-nvidia.dts;subdir=git/arch/${ARCH}/dts/ \
"

SRC_URI += "file://spl_images/prod/u-boot-spl.bin;sha256sum=6f7f2d73a9053699e3e111de1ba5a16d4f1091e01c2aa4acc5effd9cedc57f24"

SPL_PROD_BINARY = "${WORKDIR}/spl_images/prod/u-boot-spl.bin"

do_deploy:append() {
    rm -f ${DEPLOYDIR}/${SPL_IMAGE}
    rm -f ${DEPLOYDIR}/${SPL_BINARYNAME} ${DEPLOYDIR}/${SPL_SYMLINK}

    install -m 644 ${SPL_PROD_BINARY} ${DEPLOYDIR}/${SPL_IMAGE}
    ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_BINARYNAME}
    ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_SYMLINK}
}
