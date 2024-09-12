EXTRA_OEMESON += "-Ddebug_log=1"
EXTRA_OEMESON += "-Deventing_feature_only=enabled"
EXTRA_OEMESON += "-Ddevice-status-fs=enabled"
EXTRA_OEMESON += "-Ddevice-status-fs-path=/tmp/devices"

RDEPENDS:${PN}:append = " bash"
