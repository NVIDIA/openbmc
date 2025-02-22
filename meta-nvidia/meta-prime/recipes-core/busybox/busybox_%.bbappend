FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#
# The busybox config file that enables devmem also needs
# to have it enabled in the kernel in the same layer 
# (see recipes-kernel).
# Otherwise devmem will error out when run.
#
SRC_URI += " \
    file://busybox.cfg \
    ${@bb.utils.contains('BUILD_TYPE', 'prod', 'file://disable-dev-mem.cfg', 'file://enable-dev-mem.cfg', d)} \
"
