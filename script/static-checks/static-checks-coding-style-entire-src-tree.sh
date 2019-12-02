#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Check the coding style of the entire source tree against the Linux coding
# style using the checkpatch.pl script from the Linux kernel source tree.

TEST_CASE="Coding style of entire source tree"

echo "# Check coding style of the entire source tree"

LOG_FILE=$(mktemp -t coding-style-check.XXXX)

# Passing V=1 to 'make checkcodebase' will make it generate a per-file summary
CHECKPATCH=$CI_ROOT/script/static-checks/checkpatch.pl \
  make checkcodebase V=1 &> "$LOG_FILE"
RES=$?

if [[ "$RES" == 0 ]]; then
  # Ignore warnings, only mark the test as failed if there are errors.
  # We'll get as many 'total:' lines as the number of files in the source tree.
  # Search for lines that show a non-null number of errors.
  grep --quiet 'total: [^0][0-9]* errors' "$LOG_FILE"
  # grep returns 0 when it founds the pattern, which means there is an error
  RES=$?
else
  RES=0
fi

if [[ "$RES" == 0 ]]; then
  EXIT_VALUE=1
else
  EXIT_VALUE=0
fi

echo >> "$LOG_TEST_FILENAME"
echo "****** $TEST_CASE ******" >> "$LOG_TEST_FILENAME"
echo >> "$LOG_TEST_FILENAME"
if [[ "$EXIT_VALUE" == 0 ]]; then
  echo "Result : SUCCESS" >> "$LOG_TEST_FILENAME"
else
  echo "Result : FAILURE" >> "$LOG_TEST_FILENAME"
fi
# Always print the script output to show the warnings
echo >> "$LOG_TEST_FILENAME"
cat "$LOG_FILE" >> "$LOG_TEST_FILENAME"
echo >> "$LOG_TEST_FILENAME"

rm -f "$LOG_FILE"

exit "$EXIT_VALUE"
