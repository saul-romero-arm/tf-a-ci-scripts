#!/usr/bin/env bash
#
# Copyright (c) 2021, Linaro Limited
#
# SPDX-License-Identifier: BSD-3-Clause
#
# Runner for scripts in expect-post/ directory. This script is intended
# to be run from Jenkins build, with $WORKSPACE set and per-UART test
# plans prepare in artefacts/debug/run/. See expect-post/README.md for
# more info about post-expect scripts.

set -e

if [ -z "$WORKSPACE" ]; then
    echo "Error: WORKSPACE is not set. This script is intended to be run from Jenkins build. (Or suitably set up local env)."
    exit 1
fi

total=0
failed=0

for uartdir in $WORKSPACE/artefacts/debug/run/uart*; do
    uart=$(basename $uartdir)
    if [ $uart == "uart0" ]; then
        continue
    fi
    expscript=$(cat $uartdir/expect)
    if [ ! -f $WORKSPACE/tf-a-ci-scripts/expect-post/$expscript ]; then
        echo "expect-post/$expscript: MISS"
        continue
    fi
    if ! $WORKSPACE/tf-a-ci-scripts/expect-post/$expscript $WORKSPACE/lava-$uart.log; then
        echo "expect-post/$expscript($uart): FAIL"
        failed=$((failed + 1))
    else
        echo "expect-post/$expscript($uart): pass"
    fi
    total=$((total + 1))
done

echo "Post expect scripts: total=$total failed=$failed"

if [ $failed -gt 0 ]; then
    exit 1
fi
