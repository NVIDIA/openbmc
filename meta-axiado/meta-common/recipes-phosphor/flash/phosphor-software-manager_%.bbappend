FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-Add-support-to-update-u-boot-within-NOR-flash.patch \
            file://0002-Remove-Aspeed-ABR-function.patch \
            "
