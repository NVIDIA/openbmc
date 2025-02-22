SRC_URI = "git://github.com/ipmitool/ipmitool.git;protocol=https;branch=master"
SRCREV = "be11d948f89b10be094e28d8a0a5e8fb532c7b60"

DEPENDS += "systemd \
	    pkgconfig"

SRC_URI += " \
    file://iana-enterprise-numbers \
    "

# make sure that the enterprise-numbers file gets installed in the root FS
FILES:${PN} += "/usr/share/misc/iana-enterprise-numbers"
do_compile:prepend() {
    # copy the SRC_URI version of enterprise-numbers
    # to the build dir to prevent a fetch
    mkdir -p "${WORKDIR}/build"
    cp "${WORKDIR}/iana-enterprise-numbers" "${WORKDIR}/build/iana-enterprise-numbers"
}
