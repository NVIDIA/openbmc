
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

#
# The dev-mem config file should be at the same layer
# as the busybox config that enables devmem. 
# Both the kernel config and the busybox config are needed
# together for devmem to work. 
#
SRC_URI:append = " \
                   file://enable-ssif.cfg    \
                   ${@bb.utils.contains('BUILD_TYPE', 'prod', 'file://disable-dev-mem.cfg', 'file://enable-dev-mem.cfg', d)} \
                   file://otp.cfg            \
"
