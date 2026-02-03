FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://virtual_sensor_config.json"

do_install:append() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 -D ${UNPACKDIR}/virtual_sensor_config.json \
        ${D}${datadir}/${PN}/virtual_sensor_config.json
}
