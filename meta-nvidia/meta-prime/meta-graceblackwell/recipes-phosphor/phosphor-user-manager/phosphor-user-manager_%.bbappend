FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_OEMESON:append = " ${@bb.utils.contains('BUILD_TYPE', 'prod', ' -DCREATE_USER_HOME_FOLDER=false ', '', d)} "

SRC_URI:append = "${@bb.utils.contains('BUILD_TYPE', 'prod', ' file://upgrade_hostconsole_group.sh ', '', d)}"

do_install:append() {
    if [ "${BUILD_TYPE}" = "prod" ]; then
        install -d ${D}${libexecdir}
        install -m 0755 ${WORKDIR}/upgrade_hostconsole_group.sh ${D}${libexecdir}/upgrade_hostconsole_group.sh
    fi
}