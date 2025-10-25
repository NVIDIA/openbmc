OBMC_IMAGE_EXTRA_INSTALL:append = " systemd-coredump-conf"
OBMC_IMAGE_EXTRA_INSTALL += " lsof dbus-tools"

# Remove packages that the downstream NV platforms do not need
OBMC_IMAGE_EXTRA_INSTALL:remove = "wget \
    tmux \
    strace \
    phytool \
    ethtool \
    dbus-top \
    jq"

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
