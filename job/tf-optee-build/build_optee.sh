#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

ci_root="$(readlink -f "$(dirname "$0")/../..")"
source "$ci_root/utils.sh"

cd optee

# Setting up Python virtual environment with pyelftools and pycrypto
python3 -m venv python_virtualenv
source python_virtualenv/bin/activate

# wheel is not specified as pycrypto dependency but it is necessary for
# installing it.
pip install wheel
pip install pyelftools pycrypto

make PLATFORM=vexpress \
	PLATFORM_FLAVOR="${PLATFORM_FLAVOR:?}" \
	CFG_ARM64_core=y \
	CROSS_COMPILE32=arm-none-eabi-

# Deactivating Python virtual environment
deactivate

# Remove header from tee.bin
aarch64-none-elf-objcopy -O binary \
	out/arm-plat-vexpress/core/tee.elf out/arm-plat-vexpress/core/tee.bin

# Gather files to export in a single directory
mkdir -p "$workspace/artefacts"
cp out/arm-plat-vexpress/core/tee.bin "$workspace/artefacts"
