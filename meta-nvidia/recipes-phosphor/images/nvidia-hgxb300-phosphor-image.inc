OBMC_IMAGE_EXTRA_INSTALL:append:hgxb300 = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper pam-ipmi"
OBMC_IMAGE_EXTRA_INSTALL:append:hgxb300 = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', 'phosphor-user-manager-expired-password', '', d)}"

OBMC_IMAGE_EXTRA_INSTALL:remove = "systemd-analyze"
