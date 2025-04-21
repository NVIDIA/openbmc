FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " file://smbios2 \
                 "

PACKAGECONFIG:remove = " smbios-ipmi-blob"
EXTRA_OEMESON:append = " -Dplatform-prefix='HGX'"
EXTRA_OEMESON:append = " -Dcopy-cpu-version-to-model='true'"

do_install:append() {
     install -d ${D}//var/lib/smbios
     install -m 0444 ${WORKDIR}/smbios2 ${D}/var/lib/smbios
}
