FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://gen_sensor_header.py"

do_install:append() {
    python3 ${WORKDIR}/gen_sensor_header.py \
            ${WORKDIR}/smbus-telemetry-config/smbus-telemetry-config.csv \
            ${WORKDIR}/HmcSensor.hpp

    install -m 0644 ${WORKDIR}/HmcSensor.hpp ${D}${includedir}/
}
