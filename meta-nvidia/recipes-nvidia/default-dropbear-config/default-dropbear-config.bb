SUMMARY = "NVIDIA Default dropbear config update"
DESCRIPTION = "Updates default dropbear config during system bootup. This will ensure no stale config is present."
PR = "r1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = " \
            systemd \
        "
FILESEXTRAPATHS:append := "${THISDIR}/files:"

SYSTEMD_SERVICE:${PN} = "nvidia_default_dropbear_config.service"
