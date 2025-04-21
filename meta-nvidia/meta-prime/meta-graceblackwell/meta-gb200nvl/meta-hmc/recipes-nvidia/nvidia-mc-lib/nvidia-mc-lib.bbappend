FILESEXTRAPATHS:append := "${THISDIR}/files:"

SRC_URI:append = " \
	file://hmc_gpio_levels.csv \
	"

do_install:append() {
    install -d ${D}/${bindir}
    install -m 0755 ${S}/hmc_gpio_levels.csv ${D}/${bindir}/hmc_gpio_levels.csv
}
