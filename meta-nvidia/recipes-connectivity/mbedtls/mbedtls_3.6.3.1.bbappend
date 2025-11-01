# Fix SRC-URI to use nobranch instead of branch=main when using tags
# This prevents fetch failures when the tag commit is not in the main branch

SRC_URI = "git://github.com/Mbed-TLS/mbedtls.git;protocol=https;nobranch=1;tag=v${PV} \
           file://run-ptest \
           "


