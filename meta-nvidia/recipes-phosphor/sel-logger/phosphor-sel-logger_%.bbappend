# Use NVIDIA gitlab Phosphor Sel Logger
SRC_URI = "git://github.com/NVIDIA/phosphor-sel-logger;protocol=https;branch=Core-24.09-1_br"
SRCREV = "8f55bf5850b69f571654c03736ad48bff7c278b9"

DEPENDS += "phosphor-ipmi-host phosphor-logging"

inherit meson pkgconfig obmc-phosphor-ipmiprovider-symlink

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Enable threshold monitoring
EXTRA_OECMAKE += "-DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON"

PACKAGECONFIG:append = " send-to-logger"

