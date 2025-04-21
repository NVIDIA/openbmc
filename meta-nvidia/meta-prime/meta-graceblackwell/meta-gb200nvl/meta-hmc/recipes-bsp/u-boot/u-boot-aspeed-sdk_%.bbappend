FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://ast2600-gb200nvl-hmc-nvidia.dts;subdir=git/arch/${ARCH}/dts/"
SRC_URI:append = " file://gb200nvl-hmc.cfg"

SRC_URI += "file://spl_images/prod/u-boot-spl.bin;sha256sum=C4D8765510C733F237D12229CEC87A39327012846F4D2A9E84ABA2E309404F27"

SPL_PROD_BINARY = "${WORKDIR}/spl_images/prod/u-boot-spl.bin"

do_deploy:append() {
    rm -f ${DEPLOYDIR}/${SPL_IMAGE}
    rm -f ${DEPLOYDIR}/${SPL_BINARYNAME} ${DEPLOYDIR}/${SPL_SYMLINK}

    install -m 644 ${SPL_PROD_BINARY} ${DEPLOYDIR}/${SPL_IMAGE}
    ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_BINARYNAME}
    ln -sf ${SPL_IMAGE} ${DEPLOYDIR}/${SPL_SYMLINK}
}
