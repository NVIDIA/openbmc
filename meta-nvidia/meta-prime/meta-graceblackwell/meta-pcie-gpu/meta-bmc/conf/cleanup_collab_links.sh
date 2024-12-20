#!/usr/bin/env bash

sed -i 's/gitlab-collab-01.nvidia.com\/viking-team\/linux\.git;protocol=https/git@gitlab-master\.nvidia\.com:12051\/dgx\/bmc\/linux\.git;protocol=ssh/g' meta-nvidia/meta-oberon/recipes-kernel/linux/linux-aspeed_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/nvidia-ipmi-oem.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/nvidia-ipmi-oem.git;protocol=ssh/g' meta-nvidia/recipes-nvidia/nvidia-ipmi-oem/nvidia-ipmi-oem_git.bb

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/nvidia-gpuoob.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/nvidia-gpuoob.git;protocol=ssh/g' meta-nvidia/recipes-nvidia/gpuoob/nvidia-gpuoob_git.bb

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/nvidia-gpu-manager.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/nvidia-gpu-manager.git;protocol=ssh/g' meta-nvidia/recipes-nvidia/gpumgr/nvidia-gpumgr_git.bb

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/phosphor-host-ipmid.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/phosphor-host-ipmid.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/ipmi/phosphor-ipmi-host_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/phosphor-dbus-interfaces.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/phosphor-dbus-interfaces.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/dbus/phosphor-dbus-interfaces_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/phosphor-sel-logger.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/phosphor-sel-logger.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/sel-logger/phosphor-sel-logger_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/phosphor-logging.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/phosphor-logging.git;protocol=ssh/g' meta-nvidia/meta-oberon/recipes-phosphor/logging/phosphor-logging_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/libmctp.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/libmctp.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/libmctp/libmctp_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/u-boot.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/u-boot.git;protocol=ssh/g' meta-nvidia/meta-oberon/recipes-bsp/u-boot/u-boot-aspeed-sdk_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/u-boot.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/u-boot.git;protocol=ssh/g' meta-nvidia/meta-oberon/recipes-bsp/u-boot/u-boot-fw-utils-aspeed-sdk_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/bmcweb.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/bmcweb.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/bmcweb/bmcweb_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/phosphor-debug-collector.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/phosphor-debug-collector.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/dump/phosphor-debug-collector_%.bbappend

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/nvidia-oobaml.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/nvidia-oobaml.git;protocol=ssh/g' meta-nvidia/recipes-nvidia/oobaml/nvidia-oobaml_git.bb

sed -i 's/git:\/\/gitlab-collab-01.nvidia.com\/viking-team\/pldm.git;protocol=https/git:\/\/git@gitlab-master.nvidia.com:12051\/dgx\/bmc\/pldm.git;protocol=ssh/g' meta-nvidia/recipes-phosphor/pldm/pldm_%.bbappend


