SUMMARY = "Initial secure shell configuration script"
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

S = "${WORKDIR}"

SRC_URI = " \
        file://secure-shell.sh \
        file://secure-shell.service \
"

LOCAL_BIN_DIR = "${D}/usr/local/bin/nvidia"

FILES:${PN} += "\
    /usr/local/bin/nvidia \
    /usr/local/bin/nvidia/scp \
    ${bindir}/secure-shell.sh \
    /lib/systemd/system/secure-shell.service \
    /etc/systemd/system/multi-user.target.wants/secure-shell.service \
    "

do_install() {
    install -d ${D}/${bindir}
    install -m 755 ${S}/secure-shell.sh ${D}/${bindir}/
    install -m 755 -d ${LOCAL_BIN_DIR}
    install -d ${D}/lib/systemd/system/
    install -m 644 ${S}/secure-shell.service ${D}/lib/systemd/system/
    install -m 755 -d ${D}/etc/systemd/system/multi-user.target.wants
    ln -s -r ${D}/lib/systemd/system/secure-shell.service ${D}/etc/systemd/system/multi-user.target.wants/secure-shell.service
    install -d ${D}/usr/local/bin/nvidia/scp
    ln -s -r ${D}/usr/bin/scp ${D}/usr/local/bin/nvidia/scp/scp
    mkdir -p ${D}/bin
    ln -s -r ${D}/bin/bash ${D}/bin/rbash
}
