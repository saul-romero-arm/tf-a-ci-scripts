#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

ci_root="$(readlink -f "$(dirname "$0")/../..")"
source "$ci_root/utils.sh"

cd optee
make PLATFORM=vexpress PLATFORM_FLAVOR="${PLATFORM_FLAVOR:?}" CFG_ARM64_core=y

# Remove header from tee.bin
aarch64-linux-gnu-objcopy -O binary \
	out/arm-plat-vexpress/core/tee.elf out/arm-plat-vexpress/core/tee.bin

# Gather files to export in a single directory
mkdir -p "$workspace/artefacts"
cp out/arm-plat-vexpress/core/tee.bin "$workspace/artefacts"
