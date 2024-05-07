DESCRIPTION = "This package provides a simple event system on which application-specific event systems can be built."
HOMEPAGE = "https://zopeevent.readthedocs.io/en/latest/"
LICENSE = "ZPL-2.1"
LIC_FILES_CHKSUM = "file://PKG-INFO;beginline=8;endline=8;md5=72092419572155ddc2d4fb7631c63dd3"

PYPI_PACKAGE = "zope.event"

inherit pypi setuptools3
SRC_URI[sha256sum] = "bac440d8d9891b4068e2b5a2c5e2c9765a9df762944bda6955f96bb9b91e67cd"

PACKAGES =. "${PN}-test "

RPROVIDES:${PN} += "zope-event"

RDEPENDS:${PN} += " \
                  "


BBCLASSEXTEND = "native nativesdk"
