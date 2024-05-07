# forcing git hash in version with the help of --long flag  
PHOSPHOR_OS_RELEASE_DISTRO_VERSION := "${@run_git(d, 'describe --dirty --long')}"
VERSION = "${@run_git(d, 'describe --abbrev=0')}"

