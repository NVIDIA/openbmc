FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://sol-default.override.yml \
	     file://powerrestore_settings.override.yml \
             file://uuid-interface.override.yml \
             file://system-guid.sh \
             file://boot-flags.override.yml \
             file://chassis-capabilities.override.yml"

RDEPENDS:${PN} = "bash"
SYSTEMD_SERVICE:${PN} = "system-guid.service"

do_install:append () {
     install -m 0755 ${WORKDIR}/system-guid.sh ${D}/${bindir}/system-guid.sh
}

FILES:${PN} = "${bindir}/*"
