FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " git://github.com/NVIDIA/phosphor-host-ipmid;protocol=https;branch=develop;name=override;"
SRCREV_FORMAT = "override"

SRCREV_override = "fad3cf5aabcc88a89f9e82384bc32ec513fb2dc0"

SRC_URI += "file://host-ipmid-whitelist_nvidia.conf"
SRC_URI += "file://master_write_read_white_list.json"
SRC_URI += "file://phosphor-ipmi-host.conf"

WHITELIST_CONF:append = " ${UNPACKDIR}/host-ipmid-whitelist_nvidia.conf"

FILES:${PN}:append = " ${datadir}/ipmi-providers/master_write_read_white_list.json"

PACKAGECONFIG:append = " dynamic-sensors"
PACKAGECONFIG:append = " transport-oem"
EXTRA_OEMESON += "-Ddbus-logger=enabled"
EXTRA_OEMESON += "-Dmax-sel-entries=3000"
EXTRA_OEMESON += "-Denable-sensorname-algo-shortner=enabled"
EXTRA_OEMESON += "-Ddynamic-sensors-remove-exceeded-scale=enabled"

PROJECT_SRC_DIR := "${THISDIR}/${PN}"

do_configure:prepend(){
    cp -f ${PROJECT_SRC_DIR}/transporthandler_oem.cpp ${S}
}

do_install:append() {
    install -d ${D}${datadir}/ipmi-providers
    install -m 0644 ${UNPACKDIR}/master_write_read_white_list.json ${D}${datadir}/ipmi-providers
    install -m 0644 ${UNPACKDIR}/phosphor-ipmi-host.conf \
                    ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service.d/

    rm -f ${S}/transporthandler_oem.cpp
}
