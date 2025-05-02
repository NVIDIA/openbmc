#!/bin/bash
echo 'DROPBEAR_EXTRA_ARGS="-w -B"' > /etc/default/dropbear
echo '/usr/bin/rbash' >> /etc/shells
usermod service -s /usr/bin/rbash
