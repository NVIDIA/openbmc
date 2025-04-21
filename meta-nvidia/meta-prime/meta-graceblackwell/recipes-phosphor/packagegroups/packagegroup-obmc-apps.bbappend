RDEPENDS:${PN}-devtools:remove = " ${@bb.utils.contains('BUILD_TYPE', 'prod', 'lrzsz', '', d)} "
