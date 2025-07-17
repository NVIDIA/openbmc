# Use NVIDIA gitlab Phosphor Sel Logger
SRC_URI = "git://github.com/NVIDIA/phosphor-sel-logger;protocol=https;branch=develop"
SRCREV = "aac704ac8699377d6a64d1b58a07d00191dc156b"

DEPENDS += "phosphor-ipmi-host phosphor-logging"

inherit meson pkgconfig obmc-phosphor-ipmiprovider-symlink

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Enable threshold monitoring
EXTRA_OECMAKE += "-DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON"
EXTRA_OEMESON:bluesphere += "-Dsel-capacity=600"
PACKAGECONFIG:append = " send-to-logger sel-capacity"

