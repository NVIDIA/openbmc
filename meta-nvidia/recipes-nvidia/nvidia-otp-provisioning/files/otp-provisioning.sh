#!/usr/bin/env sh

export PATH="${PATH}:/sbin:/usr/sbin"

# Messages and codes
OTP_PROGRAMMING_DONE="OTP programming done"					# Code 0
OTP_PROGRAMMING_NOT_STARTED="OTP programming not started"	# Code 1
OTP_ALREADY_PROGRAMMED="OTP already programmed"				# Code 2
OTP_PROGRAMMING_FAILED="OTP programming failed"				# Code 3

OTP_BASE_DIR="${OTP_BASE_DIR:-/var/lib/otp}"
OTP_KEY_TYPE="${OTP_KEY_TYPE:-debug}"
OTP_CONSOLES="${OTP_CONSOLES:-}"
OTP_HW_ENABLED="${OTP_HW_ENABLED:-1}"
OTP_STATUS_FILE_DIR="${OTP_STATUS_FILE_DIR:-/var/lib/otp-provisioning}"

OTP_CONF_FOLDER="${OTP_BASE_DIR}/conf"
OTP_KEY_FOLDER="${OTP_BASE_DIR}/keys"
OTP_OUTPUT_FOLDER="${OTP_BASE_DIR}/out"
OTP_USER_DATA_FOLDER="${OTP_BASE_DIR}/data"
OTP_CONF_FILE="otp_config_${OTP_KEY_TYPE}.json"
OTP_PROGRAM_IMAGE="1"

uart_out() {
	for i in ${OTP_CONSOLES}; do
		echo "${1}" > /dev/${i}
	done
}

die() {
	RETCODE="${2:-1}"
	if [ ! -z "${3}" ]; then
		MESSAGE="${1} - ${3}"
	else
		MESSAGE="${1}"
	fi

	echo "${MESSAGE}"
	uart_out "[OTP] ${MESSAGE}"

	exit "${RETCODE}"
}

check_otp_provisioning_status() {
	echo "Checking OTP provisioning status..."
	STATUS=$(sed -n '1p' ${OTP_STATUS_FILE_DIR}/status)
	MISC=$(sed -n '2p' ${OTP_STATUS_FILE_DIR}/status)
	echo "OTP status - ${STATUS} - ${MISC}"

	if [ x"${STATUS}" = x"1" ]; then
		die "${OTP_ALREADY_PROGRAMMED}" 2 "${MISC} OTP configuration present"
	fi
	if [ x"${MISC}" = x"OTPDISABLED" ]; then
		echo "OTP is disabled"
		OTP_PROGRAM_IMAGE="0"
	fi
}

check_rsa_key() {
	SEQNO="${1}"
	KEY_LEN="${2:-4096}"
	KEY_NAME_PUBLIC="oem_dss_${KEY_LEN}_pub_${SEQNO}.pem"

	if [ -f "${OTP_KEY_FOLDER}/${KEY_NAME_PUBLIC}" ]; then
		return
	fi

	die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "${KEY_NAME_PUBLIC} not found"
}

generate_aes_key() {
	OUTPUT="${1}"
	KEY_LEN="${2:-32}"

	openssl rand --out "${OUTPUT}" "${KEY_LEN}" \
		|| die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "Failed to generate AES key"
}

check_key_presence() {
	AES_KEY_BIN="${OTP_KEY_FOLDER}/aes_key.bin"

	if [ ! -d "${OTP_KEY_FOLDER}" ]; then
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "${OTP_KEY_FOLDER} not found"
	fi

	if [ ! -d "${OTP_OUTPUT_FOLDER}" ]; then
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "${OTP_OUTPUT_FOLDER} not found"
	fi

	if [ ! -d "${OTP_USER_DATA_FOLDER}" ]; then
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "${OTP_USER_DATA_FOLDER} not found"
	fi

	if [ ! -f "${AES_KEY_BIN}" ]; then
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "${AES_KEY_BIN} not found"
	fi

	for seqno in $(seq 0 7); do
		check_rsa_key "${seqno}"
	done
}

generate_otp_image() {
	AES_VAULT_KEY_BIN="${OTP_KEY_FOLDER}/aes_vault.bin"
	AES_VAULT_KEY_BIN2="${OTP_KEY_FOLDER}/aes_vault2.bin"
	AES_KEY_LEN=32

	check_key_presence

	generate_aes_key "${AES_VAULT_KEY_BIN}" "${AES_KEY_LEN}"
	generate_aes_key "${AES_VAULT_KEY_BIN2}" "${AES_KEY_LEN}"

	otptool make_otp_image \
		--key_folder "${OTP_KEY_FOLDER}" \
		--user_data_folder "${OTP_USER_DATA_FOLDER}" \
		--output_folder "${OTP_OUTPUT_FOLDER}" \
		"${1}" \
		|| die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "Could not create OTP image"
}

generate_uid() {
	source="/dev/urandom"

	randpart="0x$(dd if=${source} bs=8 count=1 2>/dev/null | hexdump -e '/1 "%02x"')"
	printf "0x%x" $(( $randpart | 0xf000000000000000 ))
}

generate_otp_files() {
	echo "Generating OTP files..."
	mkdir -p "${OTP_OUTPUT_FOLDER}"

	# Create OTP user area.
	echo "Creating OTP user area..."
	otp-user-area.py \
		--config "${OTP_CONF_FOLDER}/user_area_conf_${OTP_KEY_TYPE}.yaml" \
		--output "${OTP_USER_DATA_FOLDER}"/user_area.bin \
		unique_dev_id="$(generate_uid)" \
		|| die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "User area generation failed"

	# Generate OTP image.
	echo "Generating OTP image..."
	generate_otp_image "${OTP_CONF_FOLDER}/${OTP_CONF_FILE}" \
		|| die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "OTP image generation failed"

	if [ ! -e "${OTP_OUTPUT_FOLDER}"/otp-all.image ]; then
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "OTP image file not found"
	fi
}

provision_otp() {
	# If OTP_PROGRAM_IMAGE is set to "1" we can start OTP programming.
	if [ x"${OTP_PROGRAM_IMAGE}" = x"1" ]; then
		echo "Programming OTP..."
		otp prog o "${OTP_OUTPUT_FOLDER}"/otp-all.image \
			|| die "${OTP_PROGRAMMING_FAILED}" 3 "otp prog error"
		otp pb strap o 0 1

		die "${OTP_PROGRAMMING_DONE}" 0
	else
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "Disabled by OTP_PROGRAM_IMAGE variable"
	fi
}

main() {
	echo "Starting OTP provisioning process..."
	if [ x"${OTP_HW_ENABLED}" = x"1" ]; then
		check_otp_provisioning_status
	fi
	
	generate_otp_files

	if [ x"${OTP_HW_ENABLED}" = x"1" ]; then
		provision_otp
	else
		die "${OTP_PROGRAMMING_NOT_STARTED}" 1 "Disabled by OTP_HW_ENABLED variable"
	fi
}

main
