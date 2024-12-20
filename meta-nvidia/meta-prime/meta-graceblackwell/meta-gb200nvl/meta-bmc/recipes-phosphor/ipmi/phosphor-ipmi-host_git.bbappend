FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " git://github.com/NVIDIA/phosphor-host-ipmid;protocol=https;branch=develop;name=override;"
SRCREV_FORMAT = "override"

SRCREV_override = "abc2114f5e7b33e79a7aa3cf10d52757fc3d5a7e"

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

# Remove the soft power off service in the host shutdown target install previously on .bb
SOFT_SVC = "xyz.openbmc_project.Ipmi.Internal.SoftPowerOff.service"
SOFT_TGTFMT = "obmc-host-shutdown@{0}.target"
SOFT_FMT = "../${SOFT_SVC}:${SOFT_TGTFMT}.requires/${SOFT_SVC}"
SYSTEMD_LINK:${PN}:remove = "${@compose_list_zip(d, 'SOFT_FMT', 'OBMC_HOST_INSTANCES')}"

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
