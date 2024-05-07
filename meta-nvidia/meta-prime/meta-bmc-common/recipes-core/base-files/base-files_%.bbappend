
# Add hosts entry for HMC so we don't need to hard code IP address
# (All HMC accesses should use hostname)
do_install:append () {
	echo "172.31.13.251 HMC_0" >> ${D}${sysconfdir}/hosts
}
	
