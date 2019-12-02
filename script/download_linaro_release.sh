#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Given the name of the release (e.g., 18.04), this script downloads all
# Linaro release archives to the current directory, verifies, extracts, and
# finally removes the archive files.

set -e

# Download all ZIP files from the chosen Linaro release
time wget -q -c -m -A .zip -np -nd "https://releases.linaro.org/members/arm/platforms/${1:?}/"

# Uncompress each ZIP file in its own directory (named after the ZIP file)
for zipfile in $(echo *.zip); do
	echo
	echo "Uncompressing file $zipfile"

	unzip -d "${zipfile%.zip}" "$zipfile"
done

rm -f *.zip
