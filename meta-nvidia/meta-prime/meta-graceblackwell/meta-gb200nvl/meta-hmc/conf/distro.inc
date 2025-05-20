BUILD_TYPES_WITH_SECURE_SHELL = "prod debug"
DISTRO_FEATURES:append = "${@bb.utils.contains('BUILD_TYPES_WITH_SECURE_SHELL', '${BUILD_TYPE}', 'nvidia-secure-shell', '', d)}"
#uncomment to enabled inkernel mctp
DISTRO_FEATURES += "mctp-inkernel"
