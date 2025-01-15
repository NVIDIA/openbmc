
# special handling for gb200nvl
# handle-platform-event is a temporary solution for injecting CPER events
# that will replaced by a solution that will be provided by Core team on the platform
#
# This do_install::prepend copies this binary into the oobaml/bin
# then it will be present in the TAR file only for gb200nvl-hmc
do_install:prepend() {
    if [ -s "${S}/cper/handle-platform-event" ]; then
      cp ${S}/cper/handle-platform-event ${S}/oobaml/bin/handle-platform-event
    fi
}
