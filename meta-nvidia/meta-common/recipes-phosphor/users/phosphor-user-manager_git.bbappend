FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Expired password is optional feature
PACKAGE_BEFORE_PN += "${PN}-expired-password"
SYSTEMD_PACKAGES += "${PN}-expired-password"
SYSTEMD_SERVICE:${PN}-expired-password += "first-boot-expire-password.service"
