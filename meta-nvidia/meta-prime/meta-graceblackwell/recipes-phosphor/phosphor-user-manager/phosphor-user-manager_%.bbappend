EXTRA_OEMESON:append = " ${@bb.utils.contains('BUILD_TYPE', 'prod', ' -DCREATE_USER_HOME_FOLDER=false ', '', d)} "
EXTRA_OEMESON:append:gb200nvl-bmc-dgx = "-DROOT_PRIVILEGE_USER_LIST=admin"
