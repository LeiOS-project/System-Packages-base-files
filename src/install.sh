#!/bin/sh
set -e

ROOT="${DPKG_ROOT:-}"
RAW_DIR="${ROOT}/usr/share/leios/system/utils/base-files/raw-files"
VERSION_FILE="${ROOT}/etc/leios/system/version"

log() {
    echo "leios.system.base-files-branding: $*"
}

if [ ! -f "$VERSION_FILE" ]; then
    log "warning: $VERSION_FILE not found; skipping branding generation"
    exit 0
fi

VERSION=$(tr -d '\n\r' < "$VERSION_FILE")

if [ -z "$VERSION" ]; then
    log "warning: $VERSION_FILE is empty; skipping branding generation"
    exit 0
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Files that carry the rolling-release placeholder and need to be regenerated.
FILES="os-release lsb-release issue issue.net"

for f in $FILES; do
    src="$RAW_DIR/$f"
    dst="$WORK_DIR/$f"
    if [ -f "$src" ]; then
        sed -e "s/{{INSERT_LEIOS_RELEASE}}/${VERSION}/g" "$src" > "$dst"
    else
        log "warning: raw branding file $src not found"
    fi
done

# Install the real os-release under /usr/lib and make /etc/os-release a relative symlink,
# matching the layout used by Debian and most derivatives.
install -D -m 644 "$WORK_DIR/os-release" "${ROOT}/usr/lib/os-release"
rm -f "${ROOT}/etc/os-release"
ln -sf ../usr/lib/os-release "${ROOT}/etc/os-release"

install -D -m 644 "$WORK_DIR/lsb-release" "${ROOT}/etc/lsb-release"
install -D -m 644 "$WORK_DIR/issue"       "${ROOT}/etc/issue"
install -D -m 644 "$WORK_DIR/issue.net"   "${ROOT}/etc/issue.net"

log "branding files regenerated for LeiOS ${VERSION}"
