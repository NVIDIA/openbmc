# Use NVIDIA gitlab Phosphor Sel Logger
SRC_URI = "git://github.com/NVIDIA/phosphor-sel-logger;protocol=https;branch=develop"
SRCREV = "1884c34f408e74b484689ba29ffa7abec9be7e4a"

DEPENDS += "phosphor-logging"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
# Enable threshold monitoring
EXTRA_OECMAKE += "-DSEL_LOGGER_MONITOR_THRESHOLD_EVENTS=ON"

PACKAGECONFIG:append = " send-to-logger"

