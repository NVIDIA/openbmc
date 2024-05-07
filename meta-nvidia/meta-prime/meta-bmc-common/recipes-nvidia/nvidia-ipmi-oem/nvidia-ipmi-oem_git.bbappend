SUMMARY = "NVIDIA OEM IPMI commands"
DESCRIPTION = "NVIDIA GH platform specific OEM IPMI commands"

FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"


EXTRA_OECMAKE="-Dsbmr-boot-progress=1"
EXTRA_OECMAKE +="-DGH-oem-commands=1"
EXTRA_OECMAKE +="-Ddisable-smbpbi-passthru=1"

WP_GPIO="70"
WP-GPIO-CHIP="gpiochip816"

EXTRA_OECMAKE += "-DWP-GPIO=${WP_GPIO}"
EXTRA_OECMAKE += "-DWP-GPIO-CHIP=${WP-GPIO-CHIP}"
