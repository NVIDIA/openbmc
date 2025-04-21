SUMMARY = "NVIDIA OEM IPMI commands"
DESCRIPTION = "NVIDIA GH platform specific OEM IPMI commands"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

EXTRA_OECMAKE="-Dsbmr-boot-progress=1"
EXTRA_OECMAKE +="-DGH-oem-commands=1"
EXTRA_OECMAKE +="-Ddisable-smbpbi-passthru=1"
EXTRA_OECMAKE +="-Dchassis-write-protect=Chassis_0"

EXTRA_OECMAKE += " -Dgb200-fan-enable=1 -Dgb200-pwm=4 -Dgb200-fan-ctrl=5 -Dconfig-gb200-fanZoneCtrlName1='max31790_1' -Dconfig-gb200-fanZoneCtrlName2='max31790_2' -Dconfig-gb200-fanZoneCtrlName3='max31790_3' -Dconfig-gb200-fanZoneCtrlName4='max31790_4' "

EXTRA_OECMAKE:append:gb200nvl-bmc = " -Dgb200nvl-oem-commands=1"
