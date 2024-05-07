# enable hardware interfacing and AFALG engine to use HACE module (enables symmetric encryption with vault key stored in AST2600 OTP memory)
EXTRA_OECONF:remove:class-target = "no-hw"
EXTRA_OECONF:append:class-target = "enable-engine enable-dso enable-afalgeng"
