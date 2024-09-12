SUMMARY = "NVIDIA OTP provisioning scripts."

PR = "r1"
PV = "0.1"

include nvidia-otp.inc

SRC_URI += " \
	file://README.md;sha256sum=2f36386686bfc1eddde99b7d837782f54b4d1062888e2e51c61e9fc685184386 \
	file://otp-create-image.sh;sha256sum=023c9a940a1dd1577e0d732ade6f6d86ac59ffb383666959d00b3fd3e9fe033d \
	file://otp-monitor.service;sha256sum=12cc614aaccc760520ae64ca092ca76bb9c755ebc67e01c5950421a1a15fb258 \
	file://otp-monitor.sh;sha256sum=cf83d7ad4a0d7406cbe454c8a3f7f06128b29f2ca07b8db3e2d74ba0638fe664 \
	file://otp-provisioning.service;sha256sum=c786617a921b46dd024894e8b3bfd973f16a43e06c3ddc14109b2965651b9cc5 \
	file://otp-provisioning.sh;sha256sum=5cc73d2ed1b6011a2b7ae41d5f836029510e3d272da2f63e802022615232d342 \
	file://otp-user-area.py;sha256sum=1526e913c4b0d4d7694d98af116e431ef90df383ddd76ac104cda7ddaec8ab46 \
	file://setup.py;sha256sum=61768167d440d701fde67b0d79c0d2e5c2d185b5d176a6e1cbc3f86022528d17 \
	"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS += "jq-native perl-native socsec-native xxd-native"
RDEPENDS:${PN} += "aspeed-app"
RDEPENDS:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', 'socsec', '', d)}"

RPROVIDES:${PN} += "nvidia-otp-monitor"
FILES:${PN}:append = " ${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', '${base_libdir}/systemd/system/otp-provisioning.service', '', d)}  \"

S = "${WORKDIR}"

inherit setuptools3

# force an update when rebuilding
do_install[nostamp] = "1"

PROV = "${@bb.utils.contains('DISTRO_FEATURES', 'otp-provisioning', '1', '0', d)}"

do_install() {
	install -d ${D}/${bindir}

	install -d ${D}${OTP_BASE_DIR}
	install -d ${D}${OTP_STATUS_FILE_DIR}

	install -m 0755 ${WORKDIR}/otp-monitor.sh ${D}/${bindir}/

	install -d ${D}${base_libdir}/systemd/system/
	install -m 644 ${S}/otp-monitor.service ${D}${base_libdir}/systemd/system/
	install -m 755 -d ${D}/etc/systemd/system/multi-user.target.wants
	ln -s -r ${D}${base_libdir}/systemd/system/otp-monitor.service ${D}/etc/systemd/system/multi-user.target.wants/otp-monitor.service
	mkdir -p ${D}/etc/sysconfig

	echo "OTP_BASE_DIR=${OTP_BASE_DIR}" >> ${D}/etc/sysconfig/otp-conf
	echo "OTP_HW_ENABLED=${OTP_HW_ENABLED}" > ${D}/etc/sysconfig/otp-conf
	echo "OTP_STATUS_FILE_DIR=${OTP_STATUS_FILE_DIR}" >> ${D}/etc/sysconfig/otp-conf

	printf 'OTP_CONFIGURATIONS="' >> ${D}/etc/sysconfig/otp-conf
	for CONF in ${WORKDIR}/conf/*/otp_config_*.json; do
		jq 'del(.data_region.key, .data_region.user_data)' ${CONF} > ${WORKDIR}/$(basename ${CONF})
		OUT=${WORKDIR}/otp-image-$(basename ${CONF%.*})
		mkdir -p ${OUT}
		otptool make_otp_image --output_folder ${OUT} ${WORKDIR}/$(basename ${CONF})
		perl -e 'open F,shift; do { read(F,$a,4); print scalar reverse($a);} while(!eof(F));' ${OUT}/otp-conf.bin > ${OUT}/otp-conf-rev.bin
		CONF_NAME="$(basename $(dirname ${CONF}) | tr [:lower:] [:upper:])"
		CONF_VAL="$(xxd -p ${OUT}/otp-conf-rev.bin | tr -d " \n" | head -c 32)"
		printf " ${CONF_NAME};${CONF_VAL}" >> ${D}/etc/sysconfig/otp-conf
	done
	echo '"' >> ${D}/etc/sysconfig/otp-conf

	if [ "${PROV}" = "1" ]; then
		if [ -z "${OTP_KEY_TYPE}" ]; then
			if [ "${BUILD_TYPE}" = "prod" ]; then
				OTP_KEY_TYPE="prod"
			else
				OTP_KEY_TYPE="debug"
			fi
		fi
		CONF_DIR="${WORKDIR}/conf/${OTP_KEY_TYPE}"
		KEY_DIR="${WORKDIR}/keys/${OTP_KEY_TYPE}"

		bbwarn "OTP provisioning used in ${OTP_KEY_TYPE} mode"

		install -d ${D}${OTP_BASE_DIR}/conf
		install -d ${D}${OTP_BASE_DIR}/data
		install -d ${D}${OTP_BASE_DIR}/keys

		##########################################################
		#NOTE: THESE FILES MUST BE PROVIDED BY *.bbappend layer
		#########################################################
			install -m 0644 \
				${KEY_DIR}/aes_key.bin \
				${KEY_DIR}/oem_dss_4096_pub_0.pem \
				${KEY_DIR}/oem_dss_4096_pub_1.pem \
				${KEY_DIR}/oem_dss_4096_pub_2.pem \
				${KEY_DIR}/oem_dss_4096_pub_3.pem \
				${KEY_DIR}/oem_dss_4096_pub_4.pem \
				${KEY_DIR}/oem_dss_4096_pub_5.pem \
				${KEY_DIR}/oem_dss_4096_pub_6.pem \
				${KEY_DIR}/oem_dss_4096_pub_7.pem \
				${D}${OTP_BASE_DIR}/keys/

		install -m 0644 ${CONF_DIR}/* ${D}${OTP_BASE_DIR}/conf/

		install -m 0755 ${WORKDIR}/otp-user-area.py ${D}/${bindir}/
		install -m 0755 ${WORKDIR}/otp-provisioning.sh ${D}/${bindir}/

		install -m 644 ${S}/otp-provisioning.service ${D}${base_libdir}/systemd/system/
		ln -s -r ${D}${base_libdir}/systemd/system/otp-provisioning.service ${D}/etc/systemd/system/multi-user.target.wants/otp-provisioning.service

		CONSOLES=""
		NUMBER_OF_CONSOLES=$(echo "${OTP_SERIAL_CONSOLES}" | grep -o ";" | grep -c .)
		for i in $(seq ${NUMBER_OF_CONSOLES}); do
			DEVICE=$(echo "${OTP_SERIAL_CONSOLES}" | cut -d " " -f ${i} | cut -d ";" -f 2)
			if [ -z "${CONSOLES}" ]; then
				CONSOLES="${DEVICE}"
			else
				CONSOLES="${CONSOLES} ${DEVICE}"
			fi
		done

		echo "OTP_KEY_TYPE=${OTP_KEY_TYPE}" >> ${D}/etc/sysconfig/otp-conf
		echo "OTP_CONSOLES=${CONSOLES}" >> ${D}/etc/sysconfig/otp-conf
		echo "OTP_DUMP=1" >> ${D}/etc/sysconfig/otp-conf
	else
		echo "OTP_DUMP=0" >> ${D}/etc/sysconfig/otp-conf
	fi
}

FILES:${PN} += " \
	${bindir}/otp-monitor.sh \
	${bindir}/otp-provisioning.sh \
	/etc/sysconfig/otp-conf \
	${base_libdir}/systemd/system/otp-monitor.service \
	/etc/systemd/system/multi-user.target.wants/otp-monitor.service \
	/etc/systemd/system/multi-user.target.wants/otp-provisioning.service \
	${OTP_BASE_DIR}/* \
	${OTP_STATUS_FILE_DIR} \
	"
