OBMC_IMAGE_EXTRA_INSTALL:append:hgx = " iputils libmctp pldm spdm nvidia-gpuoob nvidia-gpumgr nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:hgx-qemu = " iputils libmctp pldm spdm nvidia-gpuoob nvidia-gpumgr nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:dgx = " spdm"
OBMC_IMAGE_EXTRA_INSTALL:append:ranger = " ${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', ' switchtec ', '', d)} nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:oberon-bmc = " phosphor-health-monitor"
OBMC_IMAGE_EXTRA_INSTALL:append:oberon-hmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:hgxb = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append:gb200nvl-bmc = " phosphor-health-monitor"
OBMC_IMAGE_EXTRA_INSTALL:append:gb200nvl-hmc = " phosphor-health-monitor nvidia-debug-token-status-query-wrapper"
OBMC_IMAGE_EXTRA_INSTALL:append = " systemd-coredump-conf"

# Add the "service" account.
inherit extrausers

NVIDIA_EXTRA_USERS_PARAMS += " \
  useradd -m -d /home/service --groups priv-admin service; \
  usermod -a -G service service; \
  usermod -p '\$1\$UGMqyqdG\$FZiylVFmRRfl9Z0Ue8G7e/' service; \
  usermod -s /usr/sbin/nologin service; \
  "

# This is recipe specific to ensure it takes effect.
EXTRA_USERS_PARAMS:pn-obmc-phosphor-image += "${NVIDIA_EXTRA_USERS_PARAMS}"

BUILD_TYPES_WITH_PASSWORD_EXPIRY = "prod debug"
OBMC_IMAGE_EXTRA_INSTALL:append:hgx = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
OBMC_IMAGE_EXTRA_INSTALL:append:hgx-qemu = "${@bb.utils.contains('BUILD_TYPES_WITH_PASSWORD_EXPIRY', '${BUILD_TYPE}', ' phosphor-user-manager-expired-password', '', d)}"
