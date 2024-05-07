FILESEXTRAPATHS:prepend := "${THISDIR}:"

SRC_URI:append = " file://files/cpldi2ccmd.sh \
"

EXTRA_OEMESON:append = " -Dmodule_num=1 \
"

do_install:append() {
        install -D ${WORKDIR}/files/cpldi2ccmd.sh ${D}${bindir}/cpldi2ccmd.sh
}
