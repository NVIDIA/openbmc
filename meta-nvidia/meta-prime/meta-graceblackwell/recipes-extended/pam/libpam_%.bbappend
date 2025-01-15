FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += " file://faillock.conf \
            "

# Define deny values for debug values and prod  builds  
FAILLOCK_DENY_DEBUG ?= "0"
FAILLOCK_DENY_PROD ?= "10"
FAILLOCK_UNLOCK_TIME_DEBUG ?= "1"
FAILLOCK_UNLOCK_TIME_PROD ?= "10"
FAILLOCK_ROOT_UNLOCK_TIME_DEBUG ?= "1"
FAILLOCK_ROOT_UNLOCK_TIME_PROD ?= "10"



# Use BUILD_TYPE to determine which deny value to Use
FAILLOCK_DENY = "${@bb.utils.contains('BUILD_TYPE', 'prod', '${FAILLOCK_DENY_PROD}', '${FAILLOCK_DENY_DEBUG}', d)}"

FAILLOCK_UNLOCK_TIME = "${@bb.utils.contains('BUILD_TYPE', 'prod', '${FAILLOCK_UNLOCK_TIME_PROD}', '${FAILLOCK_UNLOCK_TIME_DEBUG}', d)}"

FAILLOCK_ROOT_UNLOCK_TIME = "${@bb.utils.contains('BUILD_TYPE', 'prod', '${FAILLOCK_ROOT_UNLOCK_TIME_PROD}', '${FAILLOCK_ROOT_UNLOCK_TIME_DEBUG}', d)}"


# Override the faillock.conf content based on the build type
do_install:append() {
    install -d ${D}${sysconfdir}/security
    cat << EOF > ${D}${sysconfdir}/security/faillock.conf
even_deny_root
deny=${FAILLOCK_DENY}
unlock_time=${FAILLOCK_UNLOCK_TIME}
root_unlock_time=${FAILLOCK_ROOT_UNLOCK_TIME}
EOF
}

