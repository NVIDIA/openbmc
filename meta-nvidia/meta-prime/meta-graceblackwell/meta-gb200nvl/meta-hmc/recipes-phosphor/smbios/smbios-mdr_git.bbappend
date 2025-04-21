#
# Enable to use only the DIMM number for locator
# Because we have the same bankLocator and deviceLocator
# No need to combine the 2 values
#
EXTRA_OEMESON:append = " -Ddimm-only-locator=enabled"
#
# Disable to register LocationCode interface of DIMM
# Because we have registered it from entity-manager by config
#
EXTRA_OEMESON:append = " -Ddimm-location-code=disabled"
