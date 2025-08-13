# Use NVIDIA gitlab Phosphor Sel Logger
SRC_URI = "git://github.com/NVIDIA/phosphor-sel-logger;protocol=https;branch=develop"
SRCREV = "e56c66a0498e5515848f5a2dfa756ecc5a62ee18"

DEPENDS += "phosphor-ipmi-host phosphor-logging"

inherit meson pkgconfig obmc-phosphor-ipmiprovider-symlink

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Enable threshold monitoring
EXTRA_OECMAKE += "-DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON"
#EXTRA_OEMESON:bluesphere += "-Dsel-capacity=600"
#PACKAGECONFIG:append = " send-to-logger sel-capacity"
PACKAGECONFIG:append = " send-to-logger"

