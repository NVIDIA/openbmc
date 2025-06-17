BUILD_TYPES_WITH_SECURE_SHELL = "prod debug"
DISTRO_FEATURES:append = "${@bb.utils.contains('BUILD_TYPES_WITH_SECURE_SHELL', '${BUILD_TYPE}', 'nvidia-secure-shell nvidia-secure-shell-debug-token-login-enable', '', d)}"

BUILTIN_USERS = "root service"
