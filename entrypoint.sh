#!/bin/bash

mkdir -p "${HOME}/.cache/mods"
mkdir -p "${HOME}/.cache/Server"
mkdir -p "${HOME}/.cache/db"

if [ -d "${HOME}/jre64" ] && [ -f "${HOME}/jre64/bin/java" ]; then
    BUNDLED_JAVA_VER=$("${HOME}/jre64/bin/java" -version 2>&1 | head -1 | grep -oP '(?<=version ")[\d]+' || echo "0")
    if [ "${BUNDLED_JAVA_VER}" -ge 21 ] 2>/dev/null; then
        echo "[PZ-Fix] Bundled JRE is Java ${BUNDLED_JAVA_VER} — swapping to Java 17..."
        if [ ! -d "${HOME}/jre64.original" ]; then
            mv "${HOME}/jre64" "${HOME}/jre64.original"
        else
            rm -rf "${HOME}/jre64"
        fi
        ln -sf "${JAVA_17_HOME}" "${HOME}/jre64"
        echo "[PZ-Fix] Now using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
    else
        echo "[PZ-Fix] Bundled JRE is Java ${BUNDLED_JAVA_VER} — OK, no swap needed."
    fi
fi

if [ "${USE_JAVA17}" = "true" ] && [ -d "${JAVA_17_HOME}" ]; then
    echo "[PZ-Fix] USE_JAVA17=true — forcing Java 17..."
    if [ -d "${HOME}/jre64" ] && [ ! -L "${HOME}/jre64" ]; then
        if [ ! -d "${HOME}/jre64.original" ]; then
            mv "${HOME}/jre64" "${HOME}/jre64.original"
        else
            rm -rf "${HOME}/jre64"
        fi
    fi
    ln -sf "${JAVA_17_HOME}" "${HOME}/jre64"
    echo "[PZ-Fix] Using: $("${HOME}/jre64/bin/java" -version 2>&1 | head -1)"
fi

MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo ":/home/container$ ${MODIFIED_STARTUP}"
eval "${MODIFIED_STARTUP}"
