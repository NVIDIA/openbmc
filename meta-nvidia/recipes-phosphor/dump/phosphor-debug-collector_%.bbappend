# Use NVIDIA gitlab Phosphor Debug Collector
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-debug-collector;protocol=https;branch=develop"
SRCREV = "3e29de658f449146db0b3a76097588db9282445a"

SRC_URI += "file://create-dump-dbus.service"

EXTRA_OEMESON += "-DBMC_DUMP_MAX_LIMIT=1"
EXTRA_OEMESON += "-DBMC_CORE_DUMP_MAX_LIMIT=1"
EXTRA_OEMESON += "-DBMC_DUMP_MAX_SIZE=8192"
EXTRA_OEMESON += "-DBMC_DUMP_TOTAL_SIZE=16384"
EXTRA_OEMESON += "-Dtests=disabled"
# Enable rotation and set min size limit to ensure we have have space to create the dump with journal 
EXTRA_OEMESON += "-Ddump_rotate_config=enabled"
EXTRA_OEMESON += "-Dfaultlog-dump-rotation=enabled"
EXTRA_OEMESON += "-DBMC_DUMP_MIN_SPACE_REQD=8192"

SRC_URI:append = " file://cper_dump.sh "

FILES:${PN}-manager +=  " \
    ${bindir}/phosphor-dump-manager \
    ${exec_prefix}/lib/tmpfiles.d/coretemp.conf \
    ${datadir}/dump/ \
    "

SYSTEMD_SERVICE:${PN}-monitor += "create-dump-dbus.service"

FILES:${PN}-monitor += " \ 
    ${bindir}/create-dump-dbus \
    /usr/local/bin/nvidia \
    "

S = "${WORKDIR}/git"
SRC_URI += "file://coretemp.conf"

do_install:append() {
    install -d ${D}${exec_prefix}/lib/tmpfiles.d
    install -m 644 ${WORKDIR}/coretemp.conf ${D}${exec_prefix}/lib/tmpfiles.d/
    install -m 755 -d ${D}/usr/local/bin/nvidia
    ln -s -r ${D}${bindir}/create-dump-dbus ${D}/usr/local/bin/nvidia/create-dump-dbus
}
