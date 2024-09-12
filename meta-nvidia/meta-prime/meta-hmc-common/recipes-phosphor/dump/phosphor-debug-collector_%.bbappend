FILESEXTRAPATHS:prepend := "${THISDIR}:"

FILESEXTRAPATHS:prepend := "${THISDIR}/ltssm_dump/:"

SRC_URI:append = " \
                   file://check_logmount.sh \
                   file://aries-link-dump.tar.gz \
                   file://hmc_dump_link_logs.bash \
                   file://retimerLtssmDump.sh "

INSANE_SKIP:${PN} += "already-stripped"

FILES:${PN}-manager +=  "${bindir}/hmc_dump_link_logs.bash"
FILES:${PN}-manager +=  "${bindir}/aries-link-dump.tar.gz"
FILES:${PN}-manager +=  "${bindir}/aries-link-dump-obmc-ast2600"
FILES:${PN}-manager +=  "${bindir}/retimerLtssmDump.sh"

