# OTP Image generation script

The script `create-otp-image.sh` can be used to generate all needed keys
(AES vault keys) as well as resulting OTP image.

## Usage
Make sure you have checked out socsec repo and correctly installed tools from it.

`otptool`

If you see help screen, the tool was installed correctly.

`sh create-otp-image.sh <config file>` where `<config file>` is one of the filenames
from the `otp` directory.
