FILESEXTRAPATHS:append := "${THISDIR}/files:"

inherit obmc-phosphor-dbus-service obmc-phosphor-systemd

RDEPENDS:${PN} = " bash "

DEPENDS += " libusb1 "

EXTRA_OEMESON += " -Denable-usb=enabled "


SYSTEMD_SERVICE:${PN}:append = " mctp-usb-ctrl@.service \
                                 mctp-usb-demux@.socket \
                                 mctp-usb-demux@.service \
                                "

SRC_URI:append= " file://mctp-usb.rules \
                  file://set-hmc-mux.sh \
                  file://mctp_cfg_smbus1.json \
                  file://mctp_cfg_smbus2.json \
                  file://mctp_cfg_smbus5.json \
                  file://mctp_cfg_smbus8.json \
                  file://mctp_cfg_smbus14.json \
                  file://mctp_cfg_smbus15.json \
                  file://mctp_cfg_spi0.json \
                  file://mctp_cfg_spi2.json \
                  file://systemd/mctp-i2c1-ctrl.service \
                  file://systemd/mctp-i2c1-demux.service \
                  file://systemd/mctp-i2c1-demux.socket \
                  file://systemd/mctp-i2c2-ctrl.service \
                  file://systemd/mctp-i2c2-demux.service \
                  file://systemd/mctp-i2c2-demux.socket \
                  file://systemd/mctp-i2c5-ctrl.service \
                  file://systemd/mctp-i2c5-demux.service \
                  file://systemd/mctp-i2c5-demux.socket \
                  file://systemd/mctp-i2c8-ctrl.service \
                  file://systemd/mctp-i2c8-demux.service \
                  file://systemd/mctp-i2c8-demux.socket \
                  file://systemd/mctp-i2c14-ctrl.service \
                  file://systemd/mctp-i2c14-demux.service \
                  file://systemd/mctp-i2c14-demux.socket \
                  file://systemd/mctp-i2c15-ctrl.service \
                  file://systemd/mctp-i2c15-demux.service \
                  file://systemd/mctp-i2c15-demux.socket \
                  file://systemd/mctp-spi0-ctrl.service \
                  file://systemd/mctp-spi0-demux.service \
                  file://systemd/mctp-spi0-demux.socket \
                  file://systemd/mctp-spi2-ctrl.service \
                  file://systemd/mctp-spi2-demux.service \
                  file://systemd/fpga0-erot-recovery.target \
                  file://systemd/fpga1-erot-recovery.target \
                  file://systemd/hmc-recovery.target \
                  file://systemd/mctp-usb-ctrl@.service \
                  file://systemd/mctp-usb-demux@.socket \
                  file://systemd/mctp-usb-demux@.service \
                  file://mctp \
                  file://mctp_cfg_usb.json \
                 "

SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-spi-demux.socket"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-ctrl.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.service"
SYSTEMD_SERVICE:${PN}:remove = " mctp-pcie-demux.socket"

SYSTEMD_SERVICE:${PN}:append = " mctp-i2c1-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c1-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c1-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c2-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c2-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c2-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c5-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c5-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c5-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c8-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c8-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c8-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c14-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c14-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c14-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c15-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c15-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-i2c15-demux.socket"

SYSTEMD_SERVICE:${PN}:append = " mctp-spi0-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi0-demux.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi0-demux.socket"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi2-ctrl.service"
SYSTEMD_SERVICE:${PN}:append = " mctp-spi2-demux.service"

SYSTEMD_SERVICE:${PN}:append = " fpga0-erot-recovery.target"
SYSTEMD_SERVICE:${PN}:append = " fpga1-erot-recovery.target"
SYSTEMD_SERVICE:${PN}:append = " hmc-recovery.target"

FILES:${PN} += "\
                   ${nonarch_base_libdir}/udev/rules.d/mctp-usb.rules \
"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/set-hmc-mux.sh ${D}/${bindir}/

    install -m 0644 ${WORKDIR}/mctp_cfg_smbus1.json ${D}${datadir}/mctp/mctp_cfg_smbus1.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus2.json ${D}${datadir}/mctp/mctp_cfg_smbus2.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus5.json ${D}${datadir}/mctp/mctp_cfg_smbus5.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus8.json ${D}${datadir}/mctp/mctp_cfg_smbus8.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus14.json ${D}${datadir}/mctp/mctp_cfg_smbus14.json
    install -m 0644 ${WORKDIR}/mctp_cfg_smbus15.json ${D}${datadir}/mctp/mctp_cfg_smbus15.json
    install -m 0644 ${WORKDIR}/mctp_cfg_spi0.json ${D}${datadir}/mctp/mctp_cfg_spi0.json
    install -m 0644 ${WORKDIR}/mctp_cfg_spi2.json ${D}${datadir}/mctp/mctp_cfg_spi2.json

    install -m 0644 ${WORKDIR}/systemd/mctp-i2c1-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c1-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c1-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c2-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c2-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c2-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c5-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c5-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c5-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c8-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c8-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c8-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c14-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c14-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c14-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c15-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c15-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-i2c15-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi0-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi0-demux.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi0-demux.socket  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi2-ctrl.service  ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-spi2-demux.service ${D}${nonarch_base_libdir}/systemd/system/

    install -m 0644 ${WORKDIR}/systemd/fpga0-erot-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/fpga1-erot-recovery.target ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/hmc-recovery.target ${D}${nonarch_base_libdir}/systemd/system/

    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-ctrl.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.service
    rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-pcie-demux.socket
    install -d ${D}${datadir}/mctp
    install -m 0644 ${WORKDIR}/mctp ${D}${datadir}/mctp/mctp
    install -m 0644 ${WORKDIR}/mctp_cfg_usb.json ${D}${datadir}/mctp/mctp_cfg_usb.json
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/mctp-usb.rules ${D}${sysconfdir}/udev/rules.d
    # For dynamic multi-bridge, only keep the template unit file
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-demux.service
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-ctrl.service
    rm -f ${D}${systemd_system_unitdir}/mctp-usb-demux.socket
    install -m 0644 ${WORKDIR}/systemd/mctp-usb-ctrl@.service ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux@.socket ${D}${nonarch_base_libdir}/systemd/system/
    install -m 0644 ${WORKDIR}/systemd/mctp-usb-demux@.service ${D}${nonarch_base_libdir}/systemd/system/
}

SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi-ctrl.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi-demux.service ', '', d)}"
SYSTEMD_SERVICE:${PN}:remove = "${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', ' mctp-spi-demux.socket ', '', d)}"

do_install:append() {
    if ${@bb.utils.contains('DISTRO_FEATURES', 'erotless-bmc', 'true', 'false', d)}; then
		bbwarn "!!!USING EROTLESS UPDATE FOR THE BMC!!!"
        rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-ctrl.service
        rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.service
        rm -f ${D}${nonarch_base_libdir}/systemd/system/mctp-spi-demux.socket
    fi
}

python do_generate_udev_rules() {
    import json
    import os
    import bb

    bb.warn("Starting the generation of udev rules.")

    # Define the work directory and the JSON and udev rules file paths
    workdir = d.getVar('WORKDIR')
    json_file_path = os.path.join(workdir, 'mctp_cfg_usb.json')
    udev_rules_path = os.path.join(workdir, '99-usb-remove.rules')

    # Ensure the directory for the udev rules file exists
    udev_dir = os.path.dirname(udev_rules_path)
    if not os.path.exists(udev_dir):
        os.makedirs(udev_dir)
    if not os.path.exists(json_file_path):
        bb.fatal(f"Required JSON configuration file not found: {json_file_path}")
    try:
        with open(json_file_path, 'r') as json_file:
            usb_configs = json.load(json_file)

        with open(udev_rules_path, 'w') as udev_file:
            udev_file.write('# This file is auto-generated. Do not edit manually.\n')
            for usb_path, services in usb_configs['usb'].items():
                # Format paths differently for each service
                parts = usb_path.split('-')
                if len(parts) > 1:
                    ctrl_path = '-'.join(parts[:2]) + '.' + '.'.join(parts[2:])
                else:
                    ctrl_path = usb_path

                parts = usb_path.split('-')

                formatted_parts = []

                if parts:
                    formatted_parts.append(parts[0])

                for i in range(1, len(parts)):
                    if i == 1:
                        formatted_parts[-1] += '-' + parts[i]
                    else:
                        formatted_parts.append(formatted_parts[-1] + '.' + parts[i])

                formatted_devpath = "/devices/platform/ahb/1e6a3000.usb/usb1/" + '/'.join(formatted_parts)

                # Generate the rule line for each USB path
                rule_line = (
                    f'SUBSYSTEM=="usb", ACTION=="remove", ENV{{DEVPATH}}=="{formatted_devpath}", '
                    f'RUN+="/usr/bin/sh -c \''
                    f'/usr/bin/systemctl stop mctp-usb-demux@{usb_path}.service; '
                    f'/usr/bin/systemctl stop mctp-usb-demux@{usb_path}.socket; '
                    f'/usr/bin/systemctl stop mctp-usb-ctrl@{ctrl_path}.service'
                    f'\'"\n'
                )
                udev_file.write(rule_line)
        
        bb.warn("Successfully generated udev rules based on JSON configuration.")
    except json.JSONDecodeError as e:
        bb.fatal(f"Error decoding JSON from {json_file_path}: {str(e)}")
    except Exception as e:
        bb.fatal(f"Unexpected error when reading {json_file_path}: {str(e)}")    

    bb.warn("DONE the generation of udev rules.")
}

addtask generate_udev_rules after do_compile before do_install

do_install:append() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-usb-remove.rules ${D}${sysconfdir}/udev/rules.d/
    bbwarn "Installed udev rules to the target directory."
}


