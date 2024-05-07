# Enable PLDM Type2
EXTRA_OEMESON:append = " -Dpldm-type2=enabled "
EXTRA_OEMESON:append = " -Dfw-debug=enabled "

#EXTRA_OEMESON:append = " -Dpldm-package-verification=disabled "

# Enable libpldmresponder for handling PlatformEventMessage request command from terminus
EXTRA_OEMESON:remove = "-Dlibpldmresponder=disabled "

EXTRA_OEMESON:append = " -Dinstance-id-expiration-interval=20 "
EXTRA_OEMESON:append = " -Dplatform-prefix='' "


