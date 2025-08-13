FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI+=" file://0001-Add-Allocate-EID-support.patch \
           file://0002-mctpd-Workaround-Bridge-Bug-for-AllocateEndpointID.patch"
