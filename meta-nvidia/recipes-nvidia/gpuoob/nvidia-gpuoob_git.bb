SUMMARY = "NVIDIA GPU OOB Module"
DESCRIPTION = "NVIDIA GPU OOB Module Library"
HOMEPAGE = "https://gitlab-master.nvidia.com/dgx/nvidia-gpuoob"
PR = "r1"
PV = "0.1+git${SRCPV}"

# Need correct license info here before upstream.
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

inherit autotools pkgconfig

DEPENDS += "autoconf-archive-native"
DEPENDS += "nlohmann-json"

# Enable for dev overrides
# GPUOOB_CFG_PATH="/usr/share/gpuoob"
GPUOOB_CFG_PATH="/run/initramfs/ro${datadir}/gpuoob"
CFG_FILE_PATH = "${datadir}/gpuoob"
# total number of all properties
TOTAL_REQ_QUE_SIZE_LIMIT = "10000"
# max properties for any of device - gpu, fpga, nvswitch
PER_DEV_REQ_QUE_SIZE_LIMIT = "1500"

CXXFLAGS += " -DCFG_FILE_PATH=\\"${GPUOOB_CFG_PATH}\\" -DWITH_DSO_HANDLE -DTOTAL_REQ_QUE_SIZE_LIMIT=${TOTAL_REQ_QUE_SIZE_LIMIT} -DPER_DEV_REQ_QUE_SIZE_LIMIT=${PER_DEV_REQ_QUE_SIZE_LIMIT}"

# Using NVIDIA Gitlab URI for OpenBMC for now, please make sure your Gitlab key doesn't have a passphase.
# You could change the passphase to empty by 'ssh-keygen -p -f ~/.ssh/<your_gitlab_id_file>'
# This issue will be solved when we upstream all codes to github.
SRC_URI += "git://github.com/NVIDIA/nvidia-gpuoob;protocol=https;branch=develop"
SRCREV = "7b26728801a881a6535198b648075c5a860f292c"
S = "${WORKDIR}/git"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
#FILESEXTRAPATHS:prepend := "${THISDIR}/files/${MACHINE}:"

SRC_URI += " \
    file://oob_cfg.json \
    file://oob_profile_delta.json \
    file://oob_properties_delta.json \
    file://oob_profile_scout.json \
    file://oob_properties_scout.json \
    file://oob_profile_vulcan.json \
    file://oob_properties_vulcan.json \
    file://dgx/ \
    file://dgx-a100-dp/ \
    file://e4830-bmc/ \
    file://e4830-hmc/ \
    file://e4869/ \
    file://falcon/ \
    file://galaxy/ \
    file://hgx/ \
    file://ranger/ \
    file://skinnyjoe/ \
    file://starship/ \
    file://hgxb/ \
    file://e4830-hgxb-hmc/ \
    file://hgxb300/ \
    file://evb-ast2600-hgxb300/ \
    file://total_req_queue_check.py \
    "

PROPS_JSON = "${WORKDIR}/oob_properties_vulcan.json"
MANIFEST_JSON = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_vulcan.json"
MANIFEST_JSON:skinnyjoe = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_skinnyjoe.json"
MANIFEST_JSON:e4869     = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_e4869.json"
MANIFEST_JSON:falcon    = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_falcon.json"
MANIFEST_JSON:starship  = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_starship.json"
MANIFEST_JSON:ranger    = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_ranger.json"
MANIFEST_JSON:galaxy    = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_galaxy.json"
MANIFEST_JSON:legocg1    = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_lego.json"
MANIFEST_JSON:legoc1    = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_lego.json"
MANIFEST_JSON:legoc2    = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_lego.json"
MANIFEST_JSON:e4830-hgxb-hmc  = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_hgxb.json"
MANIFEST_JSON:hgxb  = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_hgxb.json"
MANIFEST_JSON:e4830-hgxb300-hmc  = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_hgxb300.json"
MANIFEST_JSON:hgxb300  = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_hgxb300.json"
MANIFEST_JSON:evb-ast2600-hgxb300  = "${WORKDIR}/${MACHINE}/oob_manifest_pcie_hgxb300.json"

do_configure:prepend() {
    PROP_COUNTS=`python3 ${WORKDIR}/total_req_queue_check.py ${PROPS_JSON} ${MANIFEST_JSON}`
    TOTAL_PROP_COUNT=`echo $PROP_COUNTS | awk '{print $1}'`
    PER_DEV_PROP_COUNT=`echo $PROP_COUNTS | awk '{print $2}'`
    if [ $TOTAL_PROP_COUNT -eq 0 ]
    then
        bbwarn "ATTENTION: gpuoob config files for the platform: [${MACHINE}] appears to be incorrect"
    fi
    export CXXFLAGS="$CXXFLAGS -DTOTAL_PROP_COUNT=$TOTAL_PROP_COUNT -DPER_DEV_PROP_COUNT=$PER_DEV_PROP_COUNT"
}

do_install:append() {
    install -d ${D}${datadir}/gpuoob
    install -m 0644 ${WORKDIR}/*.json ${D}${datadir}/gpuoob/
    [ -d ${WORKDIR}/${MACHINE} ] && install -m 0644 ${WORKDIR}/${MACHINE}/*.json ${D}${datadir}/gpuoob/
}

FILES:${PN}:append = " ${libdir}/libgpu${SOLIBS}"
FILES:${PN}:append = " ${bindir}/gputool"
FILES:${PN}:append = " ${CFG_FILE_PATH}/*"
FILES:${PN}-dev:append = " ${includedir}/*.hpp"
