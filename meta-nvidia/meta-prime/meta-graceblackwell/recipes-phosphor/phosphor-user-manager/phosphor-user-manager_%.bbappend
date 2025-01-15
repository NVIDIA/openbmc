FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OEMESON:append = " ${@bb.utils.contains('BUILD_TYPE', 'prod', ' -DCREATE_USER_HOME_FOLDER=false ', '', d)} "
