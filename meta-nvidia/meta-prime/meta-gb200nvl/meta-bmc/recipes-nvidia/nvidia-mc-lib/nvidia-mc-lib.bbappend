FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " \
	file://bmc_gpio_levels.csv \
	"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${S}/bmc_gpio_levels.csv ${D}/${bindir}/bmc_gpio_levels.csv
}
