#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Script to interact with Trusted Firmware when resetting to BL31.
#
# This script is not standalone and should be sourced by a top expect script.
#

expect_re "NOTICE:  BL3-?1:" "Booting BL31"
