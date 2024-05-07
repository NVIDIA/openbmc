#!/bin/bash
echo 'DROPBEAR_EXTRA_ARGS="-w -B"' > /etc/default/dropbear
echo '/bin/rbash' >> /etc/shells
usermod service -s /bin/rbash
