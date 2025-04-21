#!/bin/sh

OTP_BASE_DIR="${OTP_BASE_DIR:-/var/lib/otp}"
USER_DATA_FOLDER="${OTP_BASE_DIR}/data"
KEY_FOLDER="${OTP_BASE_DIR}/keys"
OUTPUT_FOLDER="${PWD}/out"

die() {
	echo "${1}"
	exit $2
}

check_rsa_key() {
	SEQNO="${1}"
	KEY_LEN="${2:-4096}"
	KEY_NAME_PUBLIC="oem_dss_${KEY_LEN}_pub_${SEQNO}.pem"

	# Do not overwrite keys.
	if [ -f "${KEY_FOLDER}/${KEY_NAME_PUBLIC}" ]; then
		return
	fi

	die "RSA key was not found: ${KEY_NAME_PUBLIC}" 1
}


generate_aes_key() {
	OUTPUT="${1}"
	KEY_LEN="${2:-32}"

	echo "Generating key: ${OUTPUT}"
	openssl rand --out "${OUTPUT}" "${KEY_LEN}" \
		|| die "Could not generate AES key ${OUTPUT}."
}


check_key_presence() {
	AES_KEY_BIN="${KEY_FOLDER}/aes_key.bin"

	if [ ! -d "${KEY_FOLDER}" ]; then
		die "Folder ${KEY_FOLDER} does not exist." 1
	fi

	if [ ! -d "${OUTPUT_FOLDER}" ]; then
		die "Output folder ${OUTPUT_FOLDER} does not exist." 1
	fi

	if [ ! -d "${USER_DATA_FOLDER}" ]; then
		die "User data folder ${USER_DATA_FOLDER} does not exist." 1
	fi

	if [ ! -f "${AES_KEY_BIN}" ]; then
		die "Could not find ${AES_KEY_BIN}" 1
	fi

	for seqno in `seq 0 7`; do
		check_rsa_key "${seqno}"
	done
}

main() {
	AES_VAULT_KEY_BIN="${KEY_FOLDER}/aes_vault.bin"
	AES_VAULT_KEY_BIN2="${KEY_FOLDER}/aes_vault2.bin"
	AES_KEY_LEN=32

	check_key_presence

	echo "Creating AES vault keys."
	generate_aes_key "${AES_VAULT_KEY_BIN}" "${AES_KEY_LEN}"
	generate_aes_key "${AES_VAULT_KEY_BIN2}" "${AES_KEY_LEN}"

	echo "Making OTP image."
	otptool make_otp_image \
		--key_folder "${KEY_FOLDER}" \
		--user_data_folder "${USER_DATA_FOLDER}" \
		--output_folder "${OUTPUT_FOLDER}" \
		"${1}" || die "otptool failed" 1
}

main "${1}"
