FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://0001-do-not-use-json-schema-validator.patch \
"

RDEPENDS:${PN} += "${PYTHON_PN}-setuptools"
