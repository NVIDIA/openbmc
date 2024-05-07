OBMC_IMAGE_EXTRA_INSTALL:append = " iputils \
                                    pldm  \
                                    powerctrl \
                                    nvidia-power-monitor \
                                    ${@bb.utils.contains('DISTRO_FEATURES', 'nvidia-secure-shell', 'secure-shell', '', d)} \
                                    "
OBMC_IMAGE_EXTRA_INSTALL:append = " biosconfig-manager \
                                    bmc-post-boot-cfg \
                                    bmc-internal-network-config \
                                    nvidia-mc-aspeed-lib \
                                    nvidia-power-apps \
                                    nvidia-mac-update \
                                    phosphor-host-postd \
                                    phosphor-post-code-manager \
                                    bmc-systemd-conf \
                                    phosphor-sel-logger \
                                    phosphor-pid-control \
                                    set-hmc-time \
                                    nvidia-tal \
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
                                    write-protect \
                                  "

OBMC_IMAGE_EXTRA_INSTALL:append = " phosphor-gpio-monitor "


# TODO: temporarily commented out to maintain compatibility with CI system
# IMAGE_NAME:append = "-${BUILD_TYPE}"
# IMAGE_LINK_NAME:append = "-${BUILD_TYPE}"
