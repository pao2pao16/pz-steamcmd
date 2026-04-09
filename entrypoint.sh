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

# Determine JRE to use for Project Zomboid
# Supports both B41 (bundled jre64 directory) and B42 (symlink or missing jre64)
NEED_SYSTEM_JRE=false

if [ -L "${HOME}/jre64" ]; then
    # jre64 is a symlink — check if it points to a valid java binary
    if [ -x "${HOME}/jre64/bin/java" ]; then
        BUNDLED_JAVA_VER=$("${HOME}/jre64/bin/java" -version 2>&1 | head -1 | grep -oP '(?<=version ")[\d]+' || echo "0")
        if [ "${BUNDLED_JAVA_VER}" -ge 21 ] 2>/dev/null; then
            echo "[PZ-Fix] jre64 symlink points to Java ${BUNDLED_JAVA_VER} — swapping to Java 17..."
            NEED_SYSTEM_JRE=true
        else
            echo "[PZ-Fix] jre64 symlink points to Java ${BUNDLED_JAVA_VER} — OK."
        fi
    else
        echo "[PZ-Fix] jre64 is a broken symlink — using system Java 17..."
        NEED_SYSTEM_JRE=true
    fi
elif [ -d "${HOME}/jre64" ] && [ -f "${HOME}/jre64/bin/java" ]; then
    # jre64 is a real directory with a working java
    BUNDLED_JAVA_VER=$("${HOME}/jre64/bin/java" -version 2>&1 | head -1 | grep -oP '(?<=version ")[\d]+' || echo "0")
    if [ "${BUNDLED_JAVA_VER}" -ge 21 ] 2>/dev/null; then
        echo "[PZ-Fix] Bundled JRE is Java ${BUNDLED_JAVA_VER} — swapping to Java 17..."
        NEED_SYSTEM_JRE=true
    else
        echo "[PZ-Fix] Bundled JRE is Java ${BUNDLED_JAVA_VER} — OK, no swap needed."
    fi
else
    # jre64 doesn't exist at all
    echo "[PZ-Fix] No jre64 found — using system Java 17..."
    NEED_SYSTEM_JRE=true
fi

if [ "${NEED_SYSTEM_JRE}" = "true" ] && [ -d "${JAVA_17_HOME}" ]; then
    # Backup original jre64 if it's a real directory (not a symlink)
    if [ -d "${HOME}/jre64" ] && [ ! -L "${HOME}/jre64" ] && [ ! -d "${HOME}/jre64.original" ]; then
        mv "${HOME}/jre64" "${HOME}/jre64.original"
    else
        rm -f "${HOME}/jre64" 2>/dev/null  # Remove broken symlink or existing link
    fi
    ln -sf "${JAVA_17_HOME}" "${HOME}/jre64"
    echo "[PZ-Fix] Now using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
fi

# Manual override
if [ "${USE_JAVA17}" = "true" ] && [ -d "${JAVA_17_HOME}" ]; then
    echo "[PZ-Fix] USE_JAVA17=true — forcing Java 17..."
    if [ -d "${HOME}/jre64" ] && [ ! -L "${HOME}/jre64" ]; then
        if [ ! -d "${HOME}/jre64.original" ]; then
            mv "${HOME}/jre64" "${HOME}/jre64.original"
        else
            rm -rf "${HOME}/jre64"
        fi
    fi
    rm -f "${HOME}/jre64" 2>/dev/null
    ln -sf "${JAVA_17_HOME}" "${HOME}/jre64"
    echo "[PZ-Fix] Using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
fi

# Verify java is available before starting
if ! "${HOME}/jre64/bin/java" -version >/dev/null 2>&1; then
    echo "[PZ-Fix] ERROR: No working Java found! Server cannot start."
    exit 1
fi

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"
eval "${MODIFIED_STARTUP}"
