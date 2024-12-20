
SRC_URI = "git://github.com/NVIDIA/entity-manager;protocol=https;branch=develop file://blocklist.json"
SRCREV = "5b835433cf75ae523a520742f8163eb708a712cf"

RDEPENDS:${PN} = " \
        fru-device \
        "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
}
