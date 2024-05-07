SUMMARY = "Delete Host Interface User Service"
DESCRIPTION= "This service will monitor the bmcweb.service, if the bmcweb.service reset, then it will delete the host interfaces users on the BMC."
PR = "r1"
PV = "0.1"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd
inherit obmc-phosphor-systemd

SRC_URI = "file://delete-hi-user.service"

DEPENDS = "systemd"
RDEPENDS:${PN} = "bash"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "delete-hi-user.service"
