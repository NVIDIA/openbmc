
SRC_URI = "git://github.com/NVIDIA/entity-manager;protocol=https;branch=develop file://blocklist.json"
SRCREV = "0e3fe94ea8d6a61fffc39cefc400b833c75ce427"

RDEPENDS:${PN} = " \
        fru-device \
        "

do_install:append() {
     # Remove unnecessary config files. EntityManager spends significant time parsing these.
     rm -f ${D}/usr/share/entity-manager/configurations/*.json
}
