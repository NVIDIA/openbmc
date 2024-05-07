SUMMARY = "NVIDIA emmc partition"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI = " \
           file://emmc-partition-format.sh \
           file://nvidia-emmc-partition.service \
           "
SRC_URI:append:hgx = " file://hgx/create-partition.sh \
                       file://hgx/emmc-mount.conf"

SRC_URI:append:umbriel = " file://umbriel/create-partition.sh \
                       file://umbriel/emmc-mount.conf"

SRC_URI:append:skinnyjoe = " file://gh/create-partition.sh \
                            file://gh/emmc-mount.conf"

FILES:${PN}:append = " /usr/share/ /usr/share/emmc /usr/share/emmc-mount.conf"
DEPENDS = "systemd"
RDEPENDS:${PN} = "bash e2fsprogs-e2fsck e2fsprogs-e2fsck e2fsprogs-mke2fs e2fsprogs-tune2fs"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = " \
        nvidia-emmc-partition.service \
        "

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/emmc-partition-format.sh ${D}/${bindir}/
    mkdir -p ${D}/usr/share/emmc/
}

do_install:append:hgx() {
    install -m 0755 ${WORKDIR}/hgx/create-partition.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/hgx/emmc-mount.conf ${D}/usr/share/emmc/
}

do_install:append:umbriel() {
    install -m 0755 ${WORKDIR}/umbriel/create-partition.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/umbriel/emmc-mount.conf ${D}/usr/share/emmc/
}

do_install:append:skinnyjoe() {
    install -m 0755 ${WORKDIR}/gh/create-partition.sh ${D}/${bindir}/
    install -m 0644 ${WORKDIR}/gh/emmc-mount.conf ${D}/usr/share/emmc/
}


