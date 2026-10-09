#!/bin/sh
# This file is part of dracut fixrtc module.
# SPDX-License-Identifier: GPL-2.0-or-later

command -v getarg > /dev/null || . /lib/dracut-lib.sh

parse_timestamp() {
    # Make sure we're compatible with busybox date (this needs -D for the
    # format, while GNU and uutils reject this)
    date -u -d "$1" +%s 2> /dev/null \
        || date -u -D '%c' -d "$1" +%s 2> /dev/null
}

fixrtc() {
    local label value now last_mount t

    last_mount=0
    # dumpe2fs uses local timezone by default; force UTC
    TZ=UTC dumpe2fs -h "${root#block:}" 2> /dev/null | \
    while IFS=: read -r label value; do
        case "$label" in
            "Last mount time" | "Filesystem created")
                # If "Last mount time" is "n/a" (or unparseable) just carry on
                t=$(parse_timestamp "$value") || continue
                if [ "$t" -gt "$last_mount" ]; then
                    last_mount="$t"
                fi
                ;;
            *)
                continue
                ;;
        esac
    done

    # Bail if we didn't find a last mount time, or if it isn't later than
    # whatever the clock thinks "now" is
    [ "$last_mount" -gt 0 ] || return 0
    now=$(date -u +%s) || return 0
    [ "$last_mount" -gt "$now" ] || return 0

    # Bump last_mount forward by a minute so "now" is definitely later than
    # the last mount time
    last_mount=$((last_mount + 60))

    info "fixrtc: moving system clock forward to last mount of ${root#block:}"
    if ! date -u -s "@$last_mount" > /dev/null 2>&1; then
        warn "fixrtc: failed to set the system clock"
    fi
}

if getargbool 0 rd.fixrtc -y fixrtc; then
    if [ -n "$root" ] && [ -z "${root%%block:*}" ]; then
        fixrtc
    fi
fi
