SRC_URI = "git://github.com/NVIDIA/phosphor-certificate-manager;protocol=https;branch=develop"
SRCREV = "f8b1c65107743c03c16c7ebfb1c13b9b1a69bbf1"

PACKAGECONFIG[secure-boot-database] = "-Dconfig-secureBootDatabase=enabled,-Dconfig-secureBootDatabase=disabled"
SYSTEMD_SERVICE:${PN}:append = " \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@PK.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@KEK.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@db.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@dbt.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@dbx.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@PKDefault.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@KEKDefault.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@dbDefault.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@dbtDefault.service', '', d)} \
        ${@bb.utils.contains('PACKAGECONFIG', 'secure-boot-database', 'phosphor-certificate-manager@dbxDefault.service', '', d)} \
        "

