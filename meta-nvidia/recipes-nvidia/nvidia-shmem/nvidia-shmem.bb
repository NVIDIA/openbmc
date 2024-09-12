SUMMARY = "NVIDIA Shmem"
DESCRIPTION = "NVIDIA Shared Memory Library and Tools"
PR = "r1"
PV = "1.0+git${SRCPV}"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

inherit meson pkgconfig

S = "${WORKDIR}/git"

DEPENDS += "boost"
DEPENDS += "phosphor-logging"

SRC_URI = "git://github.com/NVIDIA/nv-shmem;protocol=https;branch=develop"
SRCREV = "2a9055a3574958afd3eeb5db3b4654dd3d8c1eaf"

EXTRA_OEMESON = "-Dtests=disabled"
FILES:${PN}:append = " ${datadir}/nvshmem/shm_mapping.json"
FILES:${PN}:append = " ${datadir}/nvshmem/shm_namespace_config.json"
