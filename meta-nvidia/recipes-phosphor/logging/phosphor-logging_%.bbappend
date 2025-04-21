SRC_URI = "git://github.com/NVIDIA/phosphor-logging;protocol=https;branch=develop"
SRCREV = "03db076ad2d88b433af2307abe9b4e20d6da4a0f"

FILESEXTRAPATHS:append := "${THISDIR}/config:"

SRC_URI:append = " \
           file://xyz.openbmc_project.Logging.service \
           "

EXTRA_OEMESON:append = " -Derror_cap=3000"
EXTRA_OEMESON:append = " -Denable_rsyslog_fwd_actions_conf=true"
EXTRA_OEMESON:append = " -Denable_log_streaming=true"
DEPENDS += "nlohmann-json"

do_install:append() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/xyz.openbmc_project.Logging.service ${D}${systemd_system_unitdir}/
}
