#!/usr/bin/env python3
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

import subprocess

def exec_prog(prog, args=[], out=None, out_text_mode=False):
    # Build the command line to execute
    cmd = [ prog ] + args

    # Spawn process.
    # Note: The standard error output is captured into the same file handle as
    # for stdout.
    process = subprocess.Popen(cmd, stdout=out, stderr=subprocess.STDOUT,
                               universal_newlines=out_text_mode, bufsize=0)
    print("Spawned process with PID %u" % process.pid)
    return process
