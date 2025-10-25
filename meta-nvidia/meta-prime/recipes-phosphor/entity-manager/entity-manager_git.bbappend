
SRC_URI = "git://github.com/NVIDIA/entity-manager;protocol=https;branch=develop file://blocklist.json"
SRCREV = "343719c7c286ed77648dc5d60cf59f5cabfd62a3"

RDEPENDS:${PN} = " \
        fru-device \
        "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
}
