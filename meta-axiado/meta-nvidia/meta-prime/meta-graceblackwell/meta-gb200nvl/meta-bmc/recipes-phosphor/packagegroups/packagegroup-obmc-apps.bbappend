RDEPENDS:${PN}-extras += "ax-usb \
                          cifs-utils\
                          mmc-utils \
                          pciutils \
                          systemd-analyze \
                          usbutils \
                          "
RDEPENDS:${PN}-extras:append:gb200nvl-bmc-axiado-github = " eipdrv-axiado shimfwl-axiado"
