
SRC_URI = "git://github.com/NVIDIA/entity-manager;protocol=https;branch=develop file://blocklist.json"
SRCREV = "f07c88a8c7ab06c95d65e4043f330887bc9aec30"

RDEPENDS:${PN} = " \
        fru-device \
        "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
}
