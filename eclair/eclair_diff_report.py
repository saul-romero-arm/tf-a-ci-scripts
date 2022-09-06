#!/usr/bin/env python3
#
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

# Script to produce cumulative "diff" report from ECLAIR individual
# per-service diff reports.

import sys
import glob


def lcut(l, prefix):
    if l.startswith(prefix):
        l = l[len(prefix):]
    return l


def process_file(fname, del_or_add):
    with open(fname) as f:
        for l in f:
            l = l.rstrip()
            if not l:
                break
        for l in f:
            if l.startswith("service "):
                l = lcut(l, "service ")
                if del_or_add == "del":
                    l = "Resolved for " + l
                else:
                    l = "Added for " + l
            elif l.startswith("End of report"):
                l = "---------------\n"
            sys.stdout.write(l)


path = "."
if len(sys.argv) > 1:
    path = sys.argv[1]

files = sorted(glob.glob(path + "/*.etr"))
#print(files)


header_done = False

for f in files:
    if "/B.EXPLAIN" in f:
        continue
    comp = f.rsplit(".", 2)
#    print("*", f, comp)
    if not header_done:
        print("=== MISRA delta report for the patch (issues resolved and/or newly added) ===\n")
        header_done = True
    process_file(f, comp[-2])

if not header_done:
    print("No new MISRA issues detected, good work!")
