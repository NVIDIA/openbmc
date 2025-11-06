
SRC_URI = "git://github.com/NVIDIA/entity-manager;protocol=https;branch=develop file://blocklist.json"
SRCREV = "a0efc295eeabb293962a7aa14f83f487fce6728b"

RDEPENDS:${PN} = " \
        fru-device \
        "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
}
