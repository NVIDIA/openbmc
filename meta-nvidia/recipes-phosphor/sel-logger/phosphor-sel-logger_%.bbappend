# Use NVIDIA gitlab Phosphor Sel Logger
SRC_URI = "git://github.com/NVIDIA/phosphor-sel-logger;protocol=https;branch=Core-24.09-1_br"
SRCREV = "03de9111010906ea079342c31ffc8af334b39a13"

DEPENDS += "phosphor-ipmi-host phosphor-logging"

inherit meson pkgconfig obmc-phosphor-ipmiprovider-symlink

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Enable threshold monitoring
EXTRA_OECMAKE += "-DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON"

PACKAGECONFIG:append = " send-to-logger"

