FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
	file://conf/prod/otp_config_prod.json;sha256sum=35f5ebff95af52ca0efe84cd5d9cc5884c0ea9976593670fe4ad050910603042 \
	file://conf/prod/user_area_conf_prod.yaml;sha256sum=fc4ae295d58cfb4aa3a81f08279a0693898ac2f07a316cde640742bcce092819 \
	file://keys/prod/aes_key.bin;sha256sum=f251b0da3d7d3cc6541002c2838c879241c174977c2182fa636eead95325e5f5 \
	file://keys/prod/oem_dss_4096_pub_0.pem;sha256sum=5f762a5c1b96675b36572c6f543cc39a30ebd87e2f2d1c5d4f0e136fd9b32738 \
	file://keys/prod/oem_dss_4096_pub_1.pem;sha256sum=78cb8f17e7996b8887bd861bb569552c7d5eb2178f1188ffecc15fab1c430ed3 \
	file://keys/prod/oem_dss_4096_pub_2.pem;sha256sum=2b63df9d9f084007a37e8be192c178ea9ea81d955fe1e952c68dbc17dd3fee5d \
	file://keys/prod/oem_dss_4096_pub_3.pem;sha256sum=9164b14902d1159d20fdff9dfc250d951514b96b7175920006134893909f72e4 \
	file://keys/prod/oem_dss_4096_pub_4.pem;sha256sum=c73a6e48eedb99f3c15a48540bc098e5f1433493b85ca40a00775a3c84b0f88b \
	file://keys/prod/oem_dss_4096_pub_5.pem;sha256sum=1778927fb6c1e33e543ae1f855f420ceed832458b4e7aa315e3bdfc7576d76af \
	file://keys/prod/oem_dss_4096_pub_6.pem;sha256sum=7d96aea2efd0e27f5180ef96fe5c5f117e0e8f10e116a9c98ce999ee338b54c1 \
	file://keys/prod/oem_dss_4096_pub_7.pem;sha256sum=51623cac8bf984cea8fd6a06f50804097deab8443bf1c8ce841f35994ec10a63 \
	"
