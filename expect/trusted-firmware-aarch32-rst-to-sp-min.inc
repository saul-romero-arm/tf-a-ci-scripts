#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Script to interact with Trusted Firmware when resetting to SP_MIN.
#
# This script is not standalone and should be sourced by a top expect script.
#

expect_string "SP_MIN:" "Booting SP_MIN"
