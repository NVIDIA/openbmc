# Use NVIDIA gitlab Phosphor Debug Collector
FILESEXTRAPATHS:prepend := "${THISDIR}/${BPN}:"
SRC_URI = "git://github.com/NVIDIA/phosphor-debug-collector;protocol=https;branch=develop"
SRCREV = "4b53c3280b30809de2b80aa0d9faaab3a1b02097"

SRC_URI += "file://create-dump-dbus.service"

EXTRA_OEMESON += "-DBMC_DUMP_MAX_LIMIT=1"
EXTRA_OEMESON += "-DBMC_DUMP_MAX_SIZE=4096"
EXTRA_OEMESON += "-DBMC_DUMP_TOTAL_SIZE=8192"
EXTRA_OEMESON += "-Dtests=disabled"
# Enable rotation and set min size limit to ensure we have have space to create the dump with journal 
EXTRA_OEMESON += "-Ddump_rotate_config=enabled"
EXTRA_OEMESON += "-Dfaultlog-dump-rotation=enabled"
EXTRA_OEMESON += "-DBMC_DUMP_MIN_SPACE_REQD=4096"

# Because /var/lib/systemd/coredump is mounted to /tmp/coredump_tmp (meta-nvidia/recipes-nvidia/base-files/base-files_%.bbappend)
# core dumps are no longer saved in jffs partition, so we need to disable jffs-workarund option.
PACKAGECONFIG[jffs-workaround] = "-Djffs-workaround=disabled"

SRC_URI:append = " file://cper_dump.sh "
SRC_URI:append = " file://dump.watchdog.conf "
SRC_URI:append = " file://coredump.watchdog.conf "

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

FILES:${PN}-manager += " ${systemd_system_unitdir}/xyz.openbmc_project.Dump.Manager.service.d/dump.watchdog.conf"
FILES:${PN}-manager += " ${systemd_system_unitdir}/obmc-dump-monitor.service.d/coredump.watchdog.conf"

SYSTEMD_OVERRIDE:${PN}-manager += "dump.watchdog.conf:xyz.openbmc_project.Dump.Manager.service.d/dump.watchdog.conf"
SYSTEMD_OVERRIDE:${PN}-manager += "coredump.watchdog.conf:obmc-dump-monitor.service.d/coredump.watchdog.conf"

do_install:append() {
    install -d ${D}${exec_prefix}/lib/tmpfiles.d
    install -m 644 ${WORKDIR}/coretemp.conf ${D}${exec_prefix}/lib/tmpfiles.d/
    install -m 755 -d ${D}/usr/local/bin/nvidia
    ln -s -r ${D}${bindir}/create-dump-dbus ${D}/usr/local/bin/nvidia/create-dump-dbus
    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.Dump.Manager.service.d
    install -d ${D}${systemd_system_unitdir}/obmc-dump-monitor.service.d
    install -m 644 ${WORKDIR}/dump.watchdog.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.Dump.Manager.service.d/
    install -m 644 ${WORKDIR}/coredump.watchdog.conf ${D}${systemd_system_unitdir}/obmc-dump-monitor.service.d/
}
