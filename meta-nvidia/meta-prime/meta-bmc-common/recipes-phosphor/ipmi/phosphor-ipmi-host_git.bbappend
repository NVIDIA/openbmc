FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " git://github.com/NVIDIA/phosphor-host-ipmid;protocol=https;branch=develop;name=override;"
SRCREV_FORMAT = "override"

SRCREV_override = "c5060766c06daf613c06a3651187cb23902b49e2"

SRC_URI += "file://host-ipmid-whitelist_nvidia.conf"
SRC_URI += "file://master_write_read_white_list.json"
SRC_URI += "file://phosphor-ipmi-host.conf"

WHITELIST_CONF:append = " ${WORKDIR}/host-ipmid-whitelist_nvidia.conf"

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
    install -m 0644 ${WORKDIR}/master_write_read_white_list.json ${D}${datadir}/ipmi-providers
    install -m 0644 ${WORKDIR}/phosphor-ipmi-host.conf \
                    ${D}${systemd_system_unitdir}/phosphor-ipmi-host.service.d/

    rm -f ${S}/transporthandler_oem.cpp
}
