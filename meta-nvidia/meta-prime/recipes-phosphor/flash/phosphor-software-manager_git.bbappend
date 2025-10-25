FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-bmc-code-mgmt;protocol=https;branch=develop"

SRCREV = "4aed0ea1e82f034cfbe850bbb5004202d8fb62a5"

EXTRA_OEMESON += " \
    -Dusb-code-update=disabled\
    -Dbmc-static-dual-image=disabled\
    -Dupdater-services=disabled\
    -Dinventory-provider=enabled\
    -Dfirmware-inventory-name=HGX_FW_BMC_0\
    -Dplatform-bmc-id=HGX_BMC_0\
    -Dside-switch-on-boot=disabled\
    -Dbmc-software-manufacturer=NVIDIA\
    -Doem-nvidia-hmc-emmc=enabled\
"

DBUS_SERVICE:${PN}-version = "xyz.openbmc_project.Software.BMC.Inventory.service"
DBUS_SERVICE:${PN}-updater = ""
FILES:${PN}-version += "${bindir}/phosphor-bmc-inventory"
