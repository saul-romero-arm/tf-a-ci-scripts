#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Script to interact with a Busybox filesystem
#
# This script is not standalone and should be sourced by a top expect script.
#

expect_string "init.sh" "Init"
expect_re ".* # " "TEST SUCCESS"
exit_uart 0
