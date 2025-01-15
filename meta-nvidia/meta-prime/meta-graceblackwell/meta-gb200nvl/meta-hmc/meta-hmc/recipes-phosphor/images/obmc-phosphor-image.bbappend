OBMC_IMAGE_EXTRA_INSTALL:append = " \
                                    iputils \
                                    pldm  \
                                    i2c-tools \
                                    ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', 'secure-shell', '', d)}  \
                                    ${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', 'nvidia-otp-provisioning', '', d)} \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = " \
                                    nsmd \
                                    nvidia-cperdecoder \
                                    cper-logger \
                                    spdm \
                                    smbios-mdr \
                                    nvidia-gpio-status-handler \
                                    nvidia-monitor-eventing \
                                   "
OBMC_IMAGE_EXTRA_INSTALL:append = " phosphor-gpio-monitor "

OBMC_IMAGE_EXTRA_INSTALL:append = " \
                                    hmc-post-boot-cfg \
                                    hmc-internal-network-config \
                                    nvidia-bmc-compliance \
                                    nvidia-mc-aspeed-lib \
                                    nvidia-tal \
                                    hmc-temp-sensor \
                                    phosphor-settings-manager \
                                    nvidia-tal \
                                    i2c-dump-server \
                                    hmc-fru-write-protect \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = "curl mctp-mockep"

IMAGE_FEATURES:remove = " \
                          obmc-fru-ipmi \
                          obmc-host-ipmi \
                          obmc-net-ipmi \
                        "

# TODO: temporarily commented out to maintain compatibility with CI system
# IMAGE_NAME:append = "-${BUILD_TYPE}"
# IMAGE_LINK_NAME:append = "-${BUILD_TYPE}"
