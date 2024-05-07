SUMMARY = "NVIDIA Event Logging"
DESCRIPTION = "Setup environment to facilitate event logging"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

DEPENDS = "\
         systemd \
         phosphor-logging \
         phosphor-dbus-interfaces \
         sdbusplus \
         "

RDEPENDS:${PN} = "bash"

FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI += " \
            file://nvidia_event_logging.sh \
           "

SYSTEMD_SERVICE:${PN} = ""

do_install:append() {
    install -d ${D}/etc/default/
    install -m 0755 ${WORKDIR}/nvidia_event_logging.sh ${D}/etc/default/
}

