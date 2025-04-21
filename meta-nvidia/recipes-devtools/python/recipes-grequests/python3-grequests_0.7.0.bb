DESCRIPTION = "GRequests allows you to use Requests with Gevent to make asynchronous HTTP Requests easily."
HOMEPAGE = "https://github.com/spyoungtech/grequests"
LICENSE = "BSD-2-Clause"
LIC_FILES_CHKSUM = "file://LICENSE;md5=52d11e5abc76d53b862b5fce68f2bacf"

SRC_URI[sha256sum] = "5c33f14268df5b8fa1107d8537815be6febbad6ec560524d6a404b7778cf6ba6"

inherit pypi setuptools3

RDEPENDS:${PN} += " \
                    python3-gevent \
                    python3-greenlet \
                    python3-zopeinterface \
		    python3-zopeevent \
                  "

CVE_PRODUCT = "grequests"

BBCLASSEXTEND = "native nativesdk"
