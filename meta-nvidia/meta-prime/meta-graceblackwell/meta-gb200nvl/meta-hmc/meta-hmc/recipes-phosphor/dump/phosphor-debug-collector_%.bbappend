system_dump_path="/var/lib/logging/dumps/system"
bmc_dump_path="/var/lib/logging/dumps/bmc"

SRC_URI:append = " file://fw_atts_dump.sh \
                   file://hw_checkout_dump.sh \
                "

EXTRA_OEMESON += "-Dfaultlog-dump-extension=enabled"
EXTRA_OEMESON += "-Dnvidia-dumps-extension=enabled"
# Directory where BMC dumps are placed
#todo: clean up DBMC_DUMP_PATH
#EXTRA_OEMESON += "-DBMC_DUMP_PATH=/var/lib/logging/dumps/bmc"

# Directory where faultlog dump are placed
#EXTRA_OEMESON += "-DFAULTLOG_DUMP_PATH=/var/lib/logging/dumps/faultlog"
# Maximum size of one system dump in kilo bytes
EXTRA_OEMESON += "-DFAULTLOG_DUMP_MAX_SIZE=500"
# Minimum space required for one system dump in kilo bytes
EXTRA_OEMESON += "-DFAULTLOG_DUMP_MIN_SPACE_REQD=50"
# Total size of the dump in kilo bytes
EXTRA_OEMESON += "-DFAULTLOG_DUMP_TOTAL_SIZE=1024"
# Total faultlog dumps to be retained on bmc, 0 represents unlimited dumps
EXTRA_OEMESON += "-DFAULTLOG_DUMP_MAX_LIMIT=0"
# The system dump manager D-Bus object path
EXTRA_OEMESON += "-DFAULTLOG_DUMP_OBJPATH=/xyz/openbmc_project/dump/faultlog"
# The system dump entry D-Bus object path
EXTRA_OEMESON += "-DFAULTLOG_DUMP_OBJ_ENTRY=/xyz/openbmc_project/dump/faultlog/entry"
# Directory where system dumps are placed
#todo: clean up DSYSTEM_DUMP_PATH
EXTRA_OEMESON += "-DFAULTLOG_DUMP_PATH=/var/lib/logging/dumps/faultlog"

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

# ADD FDR service
EXTRA_OEMESON += "-Dfdr-dump-extension=enabled"
# Directory where FDR dumps are placed
EXTRA_OEMESON += "-DFDR_DUMP_PATH=/var/emmc/fdr/dumps/fdr"
# Maximum size of one FDR dump in kilo bytes
EXTRA_OEMESON += "-DFDR_DUMP_MAX_SIZE=1024"
# Minimum space required for one FDR dump in kilo bytes
EXTRA_OEMESON += "-DFDR_DUMP_MIN_SPACE_REQD=512"
# Total size of the dump in kilo bytes
EXTRA_OEMESON += "-DFDR_DUMP_TOTAL_SIZE=10240"
# Total FDR dumps to be retained on bmc, 0 represents unlimited dumps
EXTRA_OEMESON += "-DFDR_DUMP_MAX_LIMIT=1"

FILESEXTRAPATHS:prepend := "${THISDIR}:"

RDEPENDS:${PN}-manager = "bash nvidia-cperdecoder"
FILES:${PN}-manager +=  "${bindir}/cper_dump.sh"
FILES:${PN}-manager +=  "${bindir}/fw_atts_dump.sh"
FILES:${PN}-manager +=  "${bindir}/hw_checkout_dump.sh"

do_install:append() {
    install -m 755 ${WORKDIR}/cper_dump.sh ${D}${bindir}/
    install -m 755 ${WORKDIR}/fw_atts_dump.sh ${D}${bindir}/
    install -m 755 ${WORKDIR}/hw_checkout_dump.sh ${D}${bindir}/
}

