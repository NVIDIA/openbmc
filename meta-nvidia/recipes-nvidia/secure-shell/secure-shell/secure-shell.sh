#!/bin/bash
echo '/usr/bin/rbash' >> /etc/shells
usermod service -s /usr/bin/rbash
