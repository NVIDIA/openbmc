EXTRA_OEMESON += "-Dfaultlog-dump-extension=enabled"

# Directory where faultlog dump are placed
EXTRA_OEMESON += "-DFAULTLOG_DUMP_PATH=/var/lib/logging/dumps/faultlog"
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
SRC_URI:append = " file://fw_atts_dump.sh \
                   file://hw_checkout_dump.sh \
                   file://device_mctp_eid.csv \
                "

FILESEXTRAPATHS:prepend := "${THISDIR}:"

FILES:${PN}-manager +=  "${bindir}/fw_atts_dump.sh"
FILES:${PN}-manager +=  "${bindir}/hw_checkout_dump.sh"
FILES:${PN}-manager +=  "${datadir}/device_mctp_eid.csv"

do_install:append() {
    install -m 755 ${WORKDIR}/fw_atts_dump.sh ${D}${bindir}/
    install -m 755 ${WORKDIR}/hw_checkout_dump.sh ${D}${bindir}/
    install -m 644 ${WORKDIR}/device_mctp_eid.csv ${D}${datadir}/
}

