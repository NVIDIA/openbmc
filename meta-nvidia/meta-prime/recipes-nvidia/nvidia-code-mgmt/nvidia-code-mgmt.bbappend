EXTRA_OEMESON:append = " -DDEBUG_TOKEN_SUPPORT=enabled"
EXTRA_OEMESON:append = " -DDEBUG_TOKEN_INSTALL_SUPPORTED_MODEL=Nvidia:DebugTokenInstall:76910DFA1E4C11ED861D0242AC120002"
EXTRA_OEMESON:append = " -DDEBUG_TOKEN_ERASE_SUPPORTED_MODEL=Nvidia:DebugTokenErase:76910DFA1E4C11ED861D0242AE52A53E"
EXTRA_OEMESON:append = " -DJAMPLAYER_SUPPORT=enabled -DJAMPLAYER_SUPPORTED_MODEL='Nvidia:ALTERA_FPGA:d5a6b3c28e9f4d7ca1b03f6e2c9d8a7b' "

SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenInstall.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.DebugTokenErase.Updater.service"
SYSTEMD_SERVICE:${PN}:append = " debug-token-update@.service"
SYSTEMD_SERVICE:${PN}:append = " com.Nvidia.Jamplayer.service jamplayer-flash@.service"
