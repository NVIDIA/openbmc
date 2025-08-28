FILESEXTRAPATHS:append := "${THISDIR}/files:"


PACKAGECONFIG:remove = " smbios-ipmi-blob"
EXTRA_OEMESON:append = " -Dplatform-prefix='HGX'"
EXTRA_OEMESON:append = " -Dcopy-cpu-version-to-model='true'"
