BB_DONT_CACHE = "1"
do_configure[nostamp] = "1"

BUILD_DESC = "${BUILD_TYPE}"
BUILD_DESC:append = "${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', '-prov', '-platform', d)}"
OS_RELEASE_FIELDS:append = " BUILD_DESC"
