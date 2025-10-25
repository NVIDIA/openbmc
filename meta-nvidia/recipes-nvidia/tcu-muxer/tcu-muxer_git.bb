# SPDX-FileCopyrightText: Copyright (c) 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

SUMMARY = "NVIDIA L4T T23x TCU Muxer"
PR = "r1"
PV = "0.1"

# FIXME: when get correct license info
LICENSE = "CLOSED"
LIC_FILES_CHKSUM = ""

SRC_URI = "git://git-master.nvidia.com:12001/tegra/tools/tcu_muxer.git;protocol=ssh;branch=dev-main"
SRCREV = "f536c843e365f654b4e4bf9b6ff9f37f6672d4d1"

S = "${WORKDIR}/git"

inherit pkgconfig gettext

EXTRA_OEMAKE = "CC='${CC} ${LDFLAGS}' -C '${S}' CFLAGS='${CFLAGS}'"
FILES:${PN} = "${bindir}/tcu_muxer"

do_install() {
   install -d ${D}/${bindir}
   install -m 0755 ${S}/tcu_muxer ${D}/${bindir}/
}
