OBMC_IMAGE_EXTRA_INSTALL:append:hgx = " iputils libmctp pldm spdm nvidia-gpuoob nvidia-gpumgr nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:hgx-qemu = " iputils libmctp pldm spdm nvidia-gpuoob nvidia-gpumgr nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:dgx = " spdm"
OBMC_IMAGE_EXTRA_INSTALL:append:ranger = " ${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', ' switchtec ', '', d)} nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:oberon-bmc = " phosphor-health-monitor"
OBMC_IMAGE_EXTRA_INSTALL:append:oberon-hmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper pam-ipmi"
OBMC_IMAGE_EXTRA_INSTALL:append:hgxb = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:hgxb300 = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper pam-ipmi"
OBMC_IMAGE_EXTRA_INSTALL:append:gb200nvl-bmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper pam-ipmi"
OBMC_IMAGE_EXTRA_INSTALL:append:gb200nvl-hmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper pam-ipmi"
OBMC_IMAGE_EXTRA_INSTALL:append:gb200nvl-bmc-dgx = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:gb300nvl-bmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:gb300nvl-hmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper pam-ipmi"
OBMC_IMAGE_EXTRA_INSTALL:append:hoppercb = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append = " systemd-coredump-conf"
OBMC_IMAGE_EXTRA_INSTALL += " lsof"
OBMC_IMAGE_EXTRA_INSTALL:append:juliet-bmc = " pam-ipmi "

# Add the "service" account.
inherit extrausers

SERVICE_USER_SHELL = "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', '/usr/bin/rbash', '/usr/sbin/nologin', d)}"
NVIDIA_EXTRA_USERS_PARAMS += " \
  useradd -m -d /home/service service; \
  usermod -a -G service service; \
  usermod -p '\$1\$UGMqyqdG\$FZiylVFmRRfl9Z0Ue8G7e/' service; \
  usermod -s ${SERVICE_USER_SHELL} service; \
  "

NVIDIA_EXTRA_USERS_PARAMS += "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell-debug-token-login-enable', 'groupadd secure-shell-dt-login;', '', d)}"

# This is recipe specific to ensure it takes effect.
EXTRA_USERS_PARAMS:pn-obmc-phosphor-image += "${NVIDIA_EXTRA_USERS_PARAMS}"

BUILD_TYPES_WITH_PASSWORD_EXPIRY = "prod debug"
OBMC_IMAGE_EXTRA_INSTALL:append:hgx = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
OBMC_IMAGE_EXTRA_INSTALL:append:hgx-qemu = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
OBMC_IMAGE_EXTRA_INSTALL:append:hgxb = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
OBMC_IMAGE_EXTRA_INSTALL:append:gb200nvl-bmc-dgx = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
OBMC_IMAGE_EXTRA_INSTALL:append:hgxb300 = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
