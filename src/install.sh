#!/bin/sh
set -eu

ROOT="${DPKG_ROOT:-}"
RAW_DIR="${ROOT}/usr/share/leios/system/utils/base-files/dynamic-raw-files"
META_DIR="${ROOT}/usr/share/leios/system/utils/branding-meta-files"

VERSION_FILE="${META_DIR}/leios_version"
DISTRO_FILE="${META_DIR}/leios_distro"
DISTRO_HUMAN_FILE="${META_DIR}/leios_distro_human"

log() {
    echo "leios.system.base-files-branding: $*"
}

require_metadata() {
    if [ ! -f "$1" ]; then
        log "warning: $1 not found; skipping branding generation"
        exit 0
    fi
    if [ ! -s "$1" ]; then
        log "warning: $1 is empty; skipping branding generation"
        exit 0
    fi
}

require_metadata "$VERSION_FILE"
require_metadata "$DISTRO_FILE"
require_metadata "$DISTRO_HUMAN_FILE"

VERSION=$(tr -d '\n\r' < "$VERSION_FILE")
DISTRO=$(tr -d '\n\r' < "$DISTRO_FILE")
DISTRO_HUMAN=$(tr -d '\n\r' < "$DISTRO_HUMAN_FILE")

if [ -z "$VERSION" ] || [ -z "$DISTRO" ] || [ -z "$DISTRO_HUMAN" ]; then
    log "warning: one or more metadata files are empty; skipping branding generation"
    exit 0
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

# Replace fixed placeholders with literal values in a file.
# Works by scanning each line left-to-right, so a value that happens to
# contain the text of another placeholder is never substituted again.
replace_placeholders() {
    _file="$1"
    shift
    awk '
    function replace_all(line, key, val,    result, pos, klen) {
        klen = length(key)
        result = ""
        while ((pos = index(line, key)) > 0) {
            result = result substr(line, 1, pos - 1) val
            line = substr(line, pos + klen)
        }
        return result line
    }
    BEGIN {
        n = 0
        for (i = 2; i < ARGC; i += 2) {
            n++
            key[n] = ARGV[i]
            val[n] = ARGV[i+1]
        }
        ARGC = 2
    }
    {
        line = $0
        for (i = 1; i <= n; i++) {
            line = replace_all(line, key[i], val[i])
        }
        print line
    }
    ' "$_file" "$@"
}

# Files that carry the rolling-release placeholder and need to be regenerated.
FILES="os-release lsb-release issue issue.net"

for f in $FILES; do
    if [ -f "$RAW_DIR/$f" ]; then
        cp "$RAW_DIR/$f" "$WORK_DIR/$f"
        replace_placeholders "$WORK_DIR/$f" \
            "{{INSERT_LEIOS_VERSION}}" "$VERSION" \
            "{{INSERT_LEIOS_DISTRO}}" "$DISTRO" \
            "{{INSERT_LEIOS_DISTRO_HUMAN}}" "$DISTRO_HUMAN" \
            > "$WORK_DIR/${f}.tmp"
        mv "$WORK_DIR/${f}.tmp" "$WORK_DIR/$f"
    else
        log "warning: raw branding file $RAW_DIR/$f not found"
    fi
done

install_generated() {
    if [ -f "$1" ]; then
        install -D -m 644 "$1" "$2"
    fi
}

install_generated "$WORK_DIR/os-release"   "${ROOT}/usr/lib/os-release"
install_generated "$WORK_DIR/lsb-release" "${ROOT}/etc/lsb-release"
install_generated "$WORK_DIR/issue"       "${ROOT}/etc/issue"
install_generated "$WORK_DIR/issue.net"   "${ROOT}/etc/issue.net"

log "branding files regenerated for LeiOS ${VERSION}"
