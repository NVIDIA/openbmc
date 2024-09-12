# Enable BMC web on both BMC and HMC
OBMC_IMAGE_EXTRA_INSTALL:append = " \
                                    bmcweb \
                                    spdm \
                                  "




OBMC_IMAGE_EXTRA_INSTALL:append = " \
                                    nvidia-code-mgmt \
                                    nvidia-emmc-partition \
                                    nvidia-emmc-logging \
                                    zstd \
                                    log-once \
                                    nvidia-power-manager \
                                    nvidia-otp-monitor \
                                  "
