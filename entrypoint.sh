#!/bin/bash

mkdir -p "${HOME}/.cache/mods"
mkdir -p "${HOME}/.cache/Server"
mkdir -p "${HOME}/.cache/db"

# Ensure a working JRE is available at jre64/
# B42 unstable requires Java 25+

JAVA_OK=false

# Check if jre64 has a working java binary
if [ -x "${HOME}/jre64/bin/java" ]; then
    JAVA_VER=$("${HOME}/jre64/bin/java" -version 2>&1 | head -1 | grep -oP '(?<=version ")[\d]+' || echo "0")
    echo "[PZ-Fix] jre64 has Java ${JAVA_VER}."
    JAVA_OK=true
fi

# If no working java in jre64, link system Java 25
if [ "${JAVA_OK}" = "false" ] && [ -d "${JAVA_HOME}" ]; then
    echo "[PZ-Fix] No working JRE at jre64 — linking system Java 25..."
    if [ -d "${HOME}/jre64" ] && [ ! -L "${HOME}/jre64" ] && [ ! -d "${HOME}/jre64.original" ]; then
        mv "${HOME}/jre64" "${HOME}/jre64.original"
    else
        rm -f "${HOME}/jre64" 2>/dev/null
    fi
    ln -sf "${JAVA_HOME}" "${HOME}/jre64"
    echo "[PZ-Fix] Now using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
    JAVA_OK=true
fi

# Manual override
if [ "${USE_SYSTEM_JAVA}" = "true" ] && [ -d "${JAVA_HOME}" ]; then
    echo "[PZ-Fix] USE_SYSTEM_JAVA=true — forcing system Java 25..."
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
