RDEPENDS:${PN} += " bash"
inherit systemd
EXTRA_OEMESON:append = " -Dsensor-polling-time=999 "

EXTRA_OEMESON:append = "${@bb.utils.contains('BUILD_TYPE', 'prod', ' -Dpldm-package-verification=authentication ', '', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('BUILD_TYPE', 'prod', ' -Dpldm-package-verification-must-be-signed=enabled ', '', d)}"
EXTRA_OEMESON:append = "${@bb.utils.contains('BUILD_TYPE', 'prod', ' -Dpldm-package-verification-key=2d2d2d2d2d424547494e205055424c4943204b45592d2d2d2d2d0d0a4d485977454159484b6f5a497a6a3043415159464b3445454143494459674145544a6b7039586b2b4f466d586d6d59544d726d2b507558633846784e744378630d0a47764a7244366957562f49517a386a5a6167476a2f4b4c676f45332b44346b533959546a376432327672336e627a6a56734f4479446174414a3450706d5864330d0a4537757a4165392f4d622f344b356846496944553950776a4b703276493763690d0a2d2d2d2d2d454e44205055424c4943204b45592d2d2d2d2d', '', d)}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fw_update_config.json \
                   file://pldmd.conf \
                 "

FILES:${PN}:append = " ${nonarch_base_libdir}/systemd/system/pldmd.service.d/pldmd.conf "

do_install:append() {
    rm -f ${D}${datadir}/pldm/fw_update_config.json

    mkdir -p ${D}${nonarch_base_libdir}/systemd/system/pldmd.service.d

    install -m 0644 ${WORKDIR}/fw_update_config.json ${D}${datadir}/pldm/
    install -m 0644 ${WORKDIR}/pldmd.conf ${D}${nonarch_base_libdir}/systemd/system/pldmd.service.d
}

