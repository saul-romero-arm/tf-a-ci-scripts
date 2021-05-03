#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Script to interact with an OpenEmbedded file system
#
# This script is not standalone and should be sourced by a top expect script.
#

expect_string+=('INIT:')
expect_string+=('root@genericarmv8:~#;(Power down|System halted);;shutdown -h now\r')
