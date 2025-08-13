FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Expired password is optional feature
PACKAGE_BEFORE_PN += "${PN}-expired-password"
SYSTEMD_PACKAGES += "${PN}-expired-password"
SYSTEMD_SERVICE:${PN}-expired-password += "first-boot-expire-password.service"

RDEPENDS:${PN} += "bash"

SRC_URI:append = " file://update-user-settings.conf"
SRC_URI:append = " file://update-user-settings.sh"

do_install:append() {
    install -d ${D}${libexecdir}
    install -m 0755 ${UNPACKDIR}/update-user-settings.sh ${D}${libexecdir}/

    install -d ${D}${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service.d
    install -m 0644 ${UNPACKDIR}/update-user-settings.conf ${D}${systemd_system_unitdir}/xyz.openbmc_project.User.Manager.service.d/

    mkdir -p ${D}/etc/sysconfig
    echo "BUILTIN_USERS=\"${BUILTIN_USERS}\"" >> ${D}/etc/sysconfig/update-user-settings
}
