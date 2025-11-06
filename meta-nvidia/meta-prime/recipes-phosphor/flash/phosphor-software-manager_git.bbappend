FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-bmc-code-mgmt;protocol=https;branch=develop"

SRCREV = "408b5800d1abd74df59a710194980b98c1aae50a"

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
