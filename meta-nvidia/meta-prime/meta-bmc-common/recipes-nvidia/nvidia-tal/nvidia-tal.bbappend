FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://gen_sensor_header.py"

do_install:append() {
    python3 ${UNPACKDIR}/gen_sensor_header.py \
            ${UNPACKDIR}/smbus-telemetry-config/smbus-telemetry-config.csv \
            ${UNPACKDIR}/HmcSensor.hpp

    install -m 0644 ${UNPACKDIR}/HmcSensor.hpp ${D}${includedir}/
}
