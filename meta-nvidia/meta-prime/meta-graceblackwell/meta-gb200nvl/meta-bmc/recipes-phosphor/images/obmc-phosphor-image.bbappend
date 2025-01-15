OBMC_IMAGE_EXTRA_INSTALL:append = " iputils \
                                    pldm  \
                                    powerctrl \
                                    nvidia-power-monitor \
                                    ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', 'secure-shell', '', d)} \
                                    ${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', 'nvidia-otp-provisioning', '', d)} \
                                    "
OBMC_IMAGE_EXTRA_INSTALL:append = " biosconfig-manager \
                                    bmc-post-boot-cfg \
                                    bmc-internal-network-config \
                                    cpu-diag-status \
                                    nvidia-mc-aspeed-lib \
                                    nvidia-power-apps \
                                    nvidia-mac-update \
                                    nvidia-bmc-compliance \
                                    nvidia-vmep \
                                    phosphor-host-postd \
                                    phosphor-post-code-manager \
                                    bmc-systemd-conf \
                                    phosphor-sel-logger \
                                    phosphor-pid-control \
                                    rtc-detection \
                                    set-hmc-time \
                                    nvidia-tal \
                                    i2c-dump-util \
                                    openocd \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = " ipmitool \
                                    webui-vue \
                                    phosphor-ipmi-blobs \
                                    smbios-mdr \
                                    remote-media \
                                    curl \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = " \
                                    phosphor-ipmi-ssif \
                                    nvidia-ipmi-oem \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = " libmctp \
                                    libnvme \
                                    nvidia-nvme-manager \
                                    nvidia-nvme-cpld \
                                    nsmd \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = " phosphor-gpio-monitor "


# TODO: temporarily commented out to maintain compatibility with CI system
# IMAGE_NAME:append = "-${BUILD_TYPE}"
# IMAGE_LINK_NAME:append = "-${BUILD_TYPE}"

NVIDIA_ADMIN_ACCOUNT_PARAMS = "\
  useradd --groups priv-admin,redfish,web,ipmi,hostconsole -s /bin/sh admin; \
  usermod -p '\$6\$QJXcS28/6LB9qyvS\$CQk0HXAJdi5LcRlp/P1zkwcy8MSrGppFYlvJbm5z6Q3SXt7Hg/QuD1BEXOqi9jME9vDrZdz7mxrrdki0WvVIA0' admin; \
  passwd-expire admin; \
  ${@bb.utils.contains('BUILD_TYPE', 'prod', " passwd-expire root;", '', d)} \
  ${@bb.utils.contains('BUILD_TYPE', 'prod', " usermod --lock -e 1 root;", '', d)} \
  "

EXTRA_USERS_PARAMS:pn-obmc-phosphor-image += "${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-admin-account', " ${NVIDIA_ADMIN_ACCOUNT_PARAMS}", '', d)}"
