SUMMARY = "NVIDIA Skinny Joe MAC update"
DESCRIPTION = "Update MAC Address from FRU Inventory Information for Grace servers"
PR = "r1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = " \
            systemd \
            nvidia-event-logs \
            bmc-post-boot-cfg \
        "
RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
            file://nvidia_update_mac.sh \
           "

SYSTEMD_SERVICE:${PN} = "nvidia_update_mac.service"
