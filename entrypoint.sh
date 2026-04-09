#!/bin/bash

# Default timezone to UTC
TZ=${TZ:-UTC}
export TZ

# Set internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

mkdir -p "${HOME}/.cache/mods"
mkdir -p "${HOME}/.cache/Server"
mkdir -p "${HOME}/.cache/db"

# Auto-update server via SteamCMD on boot
if [ -z "${AUTO_UPDATE}" ] || [ "${AUTO_UPDATE}" == "1" ]; then
    if [ ! -z "${SRCDS_APPID}" ]; then
        echo "Checking for game server updates..."

        if [ "${STEAM_USER}" == "" ]; then
            echo "Steam user is not set. Defaulting to anonymous user."
            STEAM_USER=anonymous
            STEAM_PASS=""
            STEAM_AUTH=""
        fi

        ./steamcmd/steamcmd.sh +force_install_dir /home/container \
            +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
            +app_update 1007 \
            +app_update ${SRCDS_APPID} \
            $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) \
            $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) \
            ${INSTALL_FLAGS} validate +quit
    else
        echo "No App ID set. Skipping update check."
    fi
else
    echo "Skipping game server update check. Auto Update is disabled."
fi

# Ensure a working JRE is available at jre64/
# B41: bundled jre64 directory (Java 17) — works as-is
# B42: jre64 may be a symlink or missing — use system Java 21

JAVA_OK=false

# Check if jre64 has a working java binary
if [ -x "${HOME}/jre64/bin/java" ]; then
    JAVA_VER=$("${HOME}/jre64/bin/java" -version 2>&1 | head -1 | grep -oP '(?<=version ")[\d]+' || echo "0")
    echo "[PZ-Fix] jre64 has Java ${JAVA_VER}."
    JAVA_OK=true
fi

# If no working java in jre64, link system Java 21
if [ "${JAVA_OK}" = "false" ] && [ -d "${JAVA_HOME}" ]; then
    echo "[PZ-Fix] No working JRE at jre64 — linking system Java 21..."
    # Backup if it's a real directory
    if [ -d "${HOME}/jre64" ] && [ ! -L "${HOME}/jre64" ] && [ ! -d "${HOME}/jre64.original" ]; then
        mv "${HOME}/jre64" "${HOME}/jre64.original"
    else
        rm -f "${HOME}/jre64" 2>/dev/null
    fi
    ln -sf "${JAVA_HOME}" "${HOME}/jre64"
    echo "[PZ-Fix] Now using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
    JAVA_OK=true
fi

# Manual override — always use system Java 21
if [ "${USE_SYSTEM_JAVA}" = "true" ] && [ -d "${JAVA_HOME}" ]; then
    echo "[PZ-Fix] USE_SYSTEM_JAVA=true — forcing system Java 21..."
    if [ -d "${HOME}/jre64" ] && [ ! -L "${HOME}/jre64" ]; then
        if [ ! -d "${HOME}/jre64.original" ]; then
            mv "${HOME}/jre64" "${HOME}/jre64.original"
        else
            rm -rf "${HOME}/jre64"
        fi
    fi
    rm -f "${HOME}/jre64" 2>/dev/null
    ln -sf "${JAVA_HOME}" "${HOME}/jre64"
    echo "[PZ-Fix] Using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
fi

# Pre-flight check
if ! "${HOME}/jre64/bin/java" -version >/dev/null 2>&1; then
    echo "[PZ-Fix] ERROR: No working Java found! Server cannot start."
    exit 1
fi

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"
eval "${MODIFIED_STARTUP}"
