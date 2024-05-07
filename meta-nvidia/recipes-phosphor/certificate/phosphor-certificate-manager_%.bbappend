SRC_URI = "git://github.com/NVIDIA/phosphor-certificate-manager;protocol=https;branch=develop"
SRCREV = "b2c33e7fb49bcf398fb455e298abec84271cc265"

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

