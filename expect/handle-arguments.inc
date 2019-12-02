#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Script to handle the arguments and initialise the expect session.
#
# This script is not standalone and should be sourced by a top expect script.

source [file join [file dirname [info script]] utils.inc]

# Store environment variables into local variables
set uart_port [get_param uart_port]
set timeout [get_param timeout]

# Open a telnet connection on the required UART port
set telnet_pid [spawn telnet localhost $uart_port]
