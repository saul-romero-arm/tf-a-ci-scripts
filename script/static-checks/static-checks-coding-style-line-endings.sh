#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

TEST_CASE="Line endings not valid"

echo "# Check Line Endings"

LOG_FILE=`mktemp -t common.XXXX`

# For all the source and doc files (*.h,*.c,*.S,*.mk,*.md)
# We only return the files that contain CRLF
find "." -\( \
    -name '*.S' -or \
    -name '*.c' -or \
    -name '*.h' -or \
    -name '*.md' -or \
    -name 'Makefile' -or \
    -name '*.mk' \
-\) -exec grep --files-with-matches $'\r$' {} \; &> "$LOG_FILE"

if [[ -s "$LOG_FILE" ]]; then
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
  echo >> "$LOG_TEST_FILENAME"
  cat "$LOG_FILE" >> "$LOG_TEST_FILENAME"
fi
echo >> "$LOG_TEST_FILENAME"

rm "$LOG_FILE"

exit "$EXIT_VALUE"

