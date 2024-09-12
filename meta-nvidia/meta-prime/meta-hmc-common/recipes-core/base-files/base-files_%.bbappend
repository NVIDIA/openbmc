
# Add hosts entry for BMC (used for debug)
do_install:append () {
	echo "172.31.13.241 BMC" >> ${D}${sysconfdir}/hosts
}
	
