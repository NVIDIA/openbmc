FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_OEMESON += "-Ddebug_log=1 \
                  -Deventing_feature_only=enabled"

SRC_URI:append = " \
    file://dat.json \
    file://event_info.json \
    file://device_mctp_eid.csv \
    file://device_id_map.csv \
    file://check_backenderror \
    file://sysvr-deviceid-wrapper \
    file://single-device-mctp-error-detection \
    file://hsc_alert_wrapper \
    file://mctp-vdm-util-wrapper \
    file://fpga_regtbl_wrapper \
    "

RDEPENDS:${PN}:append = " bash"
do_install:append() {
    install -d ${D}${datadir}/oobaml
    install -m 0644 ${WORKDIR}/dat.json ${D}${datadir}/oobaml/

    install -m 0644 ${WORKDIR}/event_info.json ${D}${datadir}/oobaml/
    install -m 0644 ${WORKDIR}/device_mctp_eid.csv ${D}${datadir}/
    install -m 0644 ${WORKDIR}/device_id_map.csv ${D}${datadir}/
    install -m 0755 ${WORKDIR}/check_backenderror ${D}${bindir}/
    install -m 0755 ${WORKDIR}/single-device-mctp-error-detection ${D}${bindir}/
    install -m 0755 ${WORKDIR}/sysvr-deviceid-wrapper ${D}${bindir}/
    install -m 0755 ${WORKDIR}/hsc_alert_wrapper ${D}${bindir}/


    sed -i "s|DEV_EID_PROFILE=\"device_mctp_eid.csv\"|DEV_EID_PROFILE=\"${datadir}/device_mctp_eid.csv\"|" ${D}${bindir}/mctp-vdm-util-wrapper

    sed -i "s|PROFILE_FILE_DIR=.*|PROFILE_FILE_DIR='${datadir}'|" ${D}${bindir}/nvlink-wp-status-wrapper
    sed -i "s|PROFILE_FILE_DIR=.*|PROFILE_FILE_DIR='${datadir}'|" ${D}${bindir}/device-id-norm.sh
}

SRC_URI:append = " file://gpio-config.json"
SRC_URI:append = " file://nvidia-oobaml.service"

FILES:${PN}:append = " ${datadir}/gpio-config.json"

do_install:append() {
    install -d ${D}/${datadir}
    install -m 0644 ${WORKDIR}/gpio-config.json ${D}/${datadir}/
}

#
# AML memory watcher configuration
#

SRC_URI:append = " file://nvidia-aml-memory-watcher.service"

SYSTEMD_SERVICE:${PN} += "nvidia-aml-memory-watcher.service"

FILES:${PN}:append = " ${bindir}/aml-memory-watcher"
FILES:${PN}:append = " ${systemd_system_unitdir}/nvidia-aml-memory-watcher.service"

