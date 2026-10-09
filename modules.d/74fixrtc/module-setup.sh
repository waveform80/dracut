#!/bin/bash
# This file is part of dracut.
# SPDX-License-Identifier: GPL-2.0-or-later

# Prerequisite check(s) for module.
check() {
    require_binaries date dumpe2fs || return 1

    # Return 255 to only include the module, if another module requires it.
    return 255
}

# Install the required file(s) and directories for the module in the initramfs.
install() {
    inst_hook pre-mount 00 "$moddir/fixrtc.sh"

    inst_multiple \
        date \
        dumpe2fs
}
