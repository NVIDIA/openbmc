EXTRA_OEMESON:append = " -Dobmc-standby-target="bmc-boot-complete.service" \
                       "

PACKAGECONFIG:remove = " only-run-apr-on-power-loss"