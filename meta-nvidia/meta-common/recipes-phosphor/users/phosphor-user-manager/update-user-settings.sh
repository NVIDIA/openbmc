#!/bin/bash

# This script is used to update the user settings for the users
# specified in the BUILTIN_USERS variable.
#
# If any of the specified users gets locked or removed in runtime,
# the script will unlock and/or re-add them on the next boot.
#
# If any of the specified users gets removed in the build configuration,
# the script will lock their account on the first boot after the update.
#
# For platforms which use only root user and do not have secure-shell
# enabled, the BUILTIN_USERS variable may be left unset or empty.

if [ -z "${BUILTIN_USERS}" ]; then
    echo "No built-in users defined"
    exit 0
fi

for U in ${BUILTIN_USERS}; do
    PASSWD_LINE=$(cat /run/initramfs/ro/etc/passwd | cut -d ":" -f 1 | grep -wn "${U}" | cut -d ":" -f 1)
    if [ -z "${PASSWD_LINE}" ]; then
        echo User ${U} not found in /etc/passwd, locking
        passwd --expire "${U}"
        usermod --lock --expire 1 "${U}"
        continue
    fi
    PASSWD_ENTRY=$(sed -n ${PASSWD_LINE}p /run/initramfs/ro/etc/passwd)

    SHADOW_LINE=$(cat /run/initramfs/ro/etc/shadow | cut -d ":" -f 1 | grep -wn "${U}" | cut -d ":" -f 1)
    if [ -z "${SHADOW_LINE}" ]; then
        echo User ${U} not found in /etc/shadow, locking
        passwd --expire "${U}"
        usermod --lock --expire 1 "${U}"
        continue
    fi
    SHADOW_ENTRY=$(sed -n ${SHADOW_LINE}p /run/initramfs/ro/etc/shadow)

    GROUP_LINES=$(cat /run/initramfs/ro/etc/group | cut -d ":" -f 4 | grep -wn "${U}" | cut -d ":" -f 1)
    USER_GROUPS=""
    for L in ${GROUP_LINES}; do
        USER_GROUP=$(sed -n ${L}p /run/initramfs/ro/etc/group | cut -d ":" -f 1)
        if ! grep -wq "${USER_GROUP}" /etc/group; then
            echo Adding group ${USER_GROUP}
            groupadd -f "${USER_GROUP}"
        fi
        USER_GROUPS="${USER_GROUPS},${USER_GROUP}"
    done
    USER_GROUPS=$(echo "${USER_GROUPS}" | sed 's/^,//')

    USER_PASS=$(echo "${SHADOW_ENTRY}" | cut -d ":" -f 2)
    USER_LOCKED=$(echo "${SHADOW_ENTRY}" | cut -d ":" -f 2 | cut -c 1)
    USER_PRIMARY_GID=$(echo "${PASSWD_ENTRY}" | cut -d ":" -f 4)
    USER_PRIMARY_GROUP=$(grep -w "${USER_PRIMARY_GID}" /run/initramfs/ro/etc/group | cut -d ":" -f 1)
    if ! grep -wq "${USER_PRIMARY_GROUP}" /etc/group; then
        echo Adding group ${USER_PRIMARY_GROUP}
        groupadd -f "${USER_PRIMARY_GROUP}"
    fi
    USER_SHELL=$(echo "${PASSWD_ENTRY}" | cut -d ":" -f 7)

    if grep -wq "${U}" /etc/passwd; then
        usermod -g "${USER_PRIMARY_GROUP}" "${U}"
        if [ ! -z "${USER_GROUPS}" ]; then
            usermod -a -G "${USER_GROUPS}" "${U}"
        fi
        if [ ! -z "${USER_SHELL}" ]; then
            usermod -s "${USER_SHELL}" "${U}"
        fi
        if [ "${USER_LOCKED}" = "!" ]; then
            echo Locking user ${U}
            passwd --expire "${U}"
            usermod --lock --expire 1 "${U}"
        elif [ $(passwd -S "${U}" | cut -d " " -f 2) = "L" ]; then
            echo Unlocking user ${U}
            passwd --unlock "${U}"
            usermod --unlock --expire -1 "${U}"
        fi
    else
        echo Adding user ${U}
        useradd -m -d "/home/${U}" "${U}"
        usermod -g "${USER_PRIMARY_GROUP}" "${U}"
        if [ ! -z "${USER_GROUPS}" ]; then
            usermod -a -G "${USER_GROUPS}" "${U}"
        fi
        if [ ! -z "${USER_PASS}" ]; then
            usermod -p "${USER_PASS}" "${U}"
        fi
        usermod -s "${USER_SHELL}" "${U}"
        passwd --expire "${U}"
        if [ "${USER_LOCKED}" = "!" ]; then
            echo Locking user ${U}
            usermod --lock --expire 1 "${U}"
        fi
    fi
done
