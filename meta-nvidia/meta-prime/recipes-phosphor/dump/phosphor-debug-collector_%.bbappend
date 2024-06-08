system_dump_path="/var/lib/logging/dumps/system"
bmc_dump_path="/var/lib/logging/dumps/bmc"

# Directory where BMC dumps are placed
#todo: clean up DBMC_DUMP_PATH 
#EXTRA_OEMESON += "-DBMC_DUMP_PATH=/var/lib/logging/dumps/bmc"

EXTRA_OEMESON += "-Dnvidia-dumps-extension=enabled"

# Directory where system dumps are placed
#todo: clean up DSYSTEM_DUMP_PATH
#EXTRA_OEMESON += "-DSYSTEM_DUMP_PATH=/var/lib/logging/dumps/system"
# Maximum size of one system dump in kilo bytes
EXTRA_OEMESON += "-DSYSTEM_DUMP_MAX_SIZE=1024"
# Minimum space required for one system dump in kilo bytes
EXTRA_OEMESON += "-DSYSTEM_DUMP_MIN_SPACE_REQD=512"
# Total size of the dump in kilo bytes
EXTRA_OEMESON += "-DSYSTEM_DUMP_TOTAL_SIZE=10240"
# Total system dumps to be retained on bmc, 0 represents unlimited dumps
EXTRA_OEMESON += "-DSYSTEM_DUMP_MAX_LIMIT=20"
# The system dump manager D-Bus object path
EXTRA_OEMESON += "-DSYSTEM_DUMP_OBJPATH=/xyz/openbmc_project/dump/system"
# The system dump entry D-Bus object path
EXTRA_OEMESON += "-DSYSTEM_DUMP_OBJ_ENTRY=/xyz/openbmc_project/dump/system/entry"

# The Manager bmc dump macro
EXTRA_OEMESON += "-DBMC_DUMP_MAX_SIZE=20480"
EXTRA_OEMESON += "-DBMC_DUMP_TOTAL_SIZE=20992"
EXTRA_OEMESON += "-DBMC_DUMP_MIN_SPACE_REQD=20480"
EXTRA_OEMESON += "-DCOMPRESSION_TYPE=zstd"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://fpga_dump.sh \
                   file://fpga_register_table_info.csv \
                   file://selftest_dump.sh \
                   file://erot_dump.sh \
                   file://dump.fs_dep.conf \
                   file://check_logmount.sh "


FILES:${PN}-manager +=  "${bindir}/fpga_dump.sh"
FILES:${PN}-manager +=  "${datadir}/fpga_register_table_info.csv"
FILES:${PN}-manager +=  "${bindir}/selftest_dump.sh"
FILES:${PN}-manager +=  "${bindir}/erot_dump.sh"
FILES:${PN}-manager +=  "${bindir}/check_logmount.sh"

RDEPENDS:${PN}-manager += "bash"
RDEPENDS:${PN}-manager += "i2c-tools"
RDEPENDS:${PN} += "bash"
RDEPENDS:${PN} += "i2c-tools"

SYSTEMD_OVERRIDE:${PN}-manager += "dump.fs_dep.conf:xyz.openbmc_project.Dump.Manager.service.d/dump.fs_dep.conf"

do_install:append() {
    install -m 755 ${WORKDIR}/fpga_dump.sh ${D}${bindir}/
    install -m 755 ${WORKDIR}/fpga_register_table_info.csv ${D}${datadir}/
    install -m 755 ${WORKDIR}/selftest_dump.sh ${D}${bindir}/
    install -m 755 ${WORKDIR}/erot_dump.sh ${D}${bindir}/
    install -m 755 ${WORKDIR}/check_logmount.sh ${D}${bindir}/
}

install_nvidia_plugins() {
    install ${S}/tools/dreport.d/nvidia.d/common.d/* ${D}${dreport_plugin_dir}/
}

#Link in the plugins so dreport run them at the appropriate time
python link_nvidia_plugins() {
    source = d.getVar('S', True)
    source_path = os.path.join(source, "tools", "dreport.d", "nvidia.d", "common.d")
    op_plugins = os.listdir(source_path)
    for op_plugin in op_plugins:
        op_plugin_name = os.path.join(source_path, op_plugin)
        install_dreport_user_script(op_plugin_name, d)
}

NVIDIA_INSTALL_POSTFUNCS = "install_nvidia_plugins link_nvidia_plugins"

do_install[postfuncs] += "${NVIDIA_INSTALL_POSTFUNCS}"

