FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI = "git://github.com/NVIDIA/phosphor-bmc-code-mgmt;protocol=https;branch=Core-24.09-1_br"

SRCREV = "7fa33ef92fbfd9bdf0c68416eec59a88ff553ed3"

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
