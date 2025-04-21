FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://channel_config.json \
                   file://channel_access.json "

SRC_URI:append:gb200nvl-bmc-ut3 = " file://gb200nvl-bmc-ut3/channel_config.json \
                                    file://gb200nvl-bmc-ut3/channel_access.json "

do_install:append() {
    install -m 0644 -D ${WORKDIR}/channel_config.json \
        ${D}${datadir}/ipmi-providers/channel_config.json

    install -m 0644 -D ${WORKDIR}/channel_access.json \
        ${D}${datadir}/ipmi-providers/channel_access.json
}
