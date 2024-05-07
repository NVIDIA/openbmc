EXTRA_OEMESON += " \
    -Doem-nvidia=enabled \
    "

SYSTEMD_SERVICE:${PN} += "nvidia-erot-time-manager.service"
