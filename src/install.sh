#!/bin/sh
set -eu

ROOT="${DPKG_ROOT:-}"
RAW_DIR="${ROOT}/usr/share/leios/system/utils/base-files/dynamic-raw-files"
VERSION_FILE="${ROOT}/usr/share/leios/system/utils/branding-meta-files/leios_version"
DISTRO_FILE="${ROOT}/usr/share/leios/system/utils/branding-meta-files/leios_distro"
DISTRO_HUMAN_FILE="${ROOT}/usr/share/leios/system/utils/branding-meta-files/leios_distro_human"

log() {
    echo "leios.system.base-files-branding: $*"
}

if [ ! -f "$VERSION_FILE" ]; then
    log "warning: $VERSION_FILE not found; skipping branding generation"
    exit 0
fi

VERSION=$(tr -d '\n\r' < "$VERSION_FILE")
DISTRO=$(tr -d '\n\r' < "$DISTRO_FILE")
DISTRO_HUMAN=$(tr -d '\n\r' < "$DISTRO_HUMAN_FILE")

if [ -z "$VERSION" ]; then
    log "warning: $VERSION_FILE is empty; skipping branding generation"
    exit 0
fi
if [ -z "$DISTRO" ]; then
    log "warning: $DISTRO_FILE is empty; skipping branding generation"
    exit 0
fi
if [ -z "$DISTRO_HUMAN" ]; then
    log "warning: $DISTRO_HUMAN_FILE is empty; skipping branding generation"
    exit 0
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Files that carry the rolling-release placeholder and need to be regenerated.
FILES="os-release lsb-release issue issue.net"

for f in $FILES; do
    if [ -f "$RAW_DIR/$f" ]; then
        cp "$RAW_DIR/$f" "$WORK_DIR/$f"
        sed -i "s/{{INSERT_LEIOS_VERSION}}/${VERSION}/g" "$WORK_DIR/$f"
        sed -i "s/{{INSERT_LEIOS_DISTRO}}/${DISTRO}/g" "$WORK_DIR/$f"
        sed -i "s/{{INSERT_LEIOS_DISTRO_HUMAN}}/${DISTRO_HUMAN}/g" "$WORK_DIR/$f"
    else
        log "warning: raw branding file $RAW_DIR/$f not found"
    fi
done

install -D -m 644 "$WORK_DIR/os-release"   "${ROOT}/usr/lib/os-release"
install -D -m 644 "$WORK_DIR/lsb-release" "${ROOT}/etc/lsb-release"
install -D -m 644 "$WORK_DIR/issue"       "${ROOT}/etc/issue"
install -D -m 644 "$WORK_DIR/issue.net"   "${ROOT}/etc/issue.net"

log "branding files regenerated for LeiOS ${VERSION}"
