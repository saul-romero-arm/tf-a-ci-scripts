#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

echo '----------------------------------------------'
echo '-- Running static checks on the source code --'
echo '----------------------------------------------'

# Find the absolute path of the scripts' top directory

cd "$(dirname "$0")/../.."
export CI_ROOT=$(pwd)
cd -

# Initialize log file

export LOG_TEST_FILENAME=$(pwd)/static-checks.log

echo
echo "###### Static checks ######"
echo

echo "###### Static checks ######" > "$LOG_TEST_FILENAME"
echo >> "$LOG_TEST_FILENAME"

# Reset error counters

ERROR_COUNT=0
WARNING_COUNT=0

# Ensure all the files contain a copyright

echo 'Checking copyright in source files...'
echo
"$CI_ROOT"/script/static-checks/static-checks-check-copyright.sh .
if [ "$?" != 0 ]; then
  echo "Copyright test: FAILURE"
  ((ERROR_COUNT++))
else
  echo "Copyright test: PASS"
fi
echo

# Check alphabetic order of headers included.

if [ "$IS_CONTINUOUS_INTEGRATION" == 1 ]; then
    "$CI_ROOT"/script/static-checks/static-checks-include-order.sh . patch
else
    "$CI_ROOT"/script/static-checks/static-checks-include-order.sh .
fi
if [ "$?" != 0 ]; then
  echo "Include order test: FAILURE"
  ((WARNING_COUNT++))
else
  echo "Include order test: PASS"
fi
echo

# Check line endings

if [ "$IS_CONTINUOUS_INTEGRATION" == 1 ]; then
    "$CI_ROOT"/script/static-checks/static-checks-coding-style-line-endings.sh . patch
else
    "$CI_ROOT"/script/static-checks/static-checks-coding-style-line-endings.sh
fi

if [ "$?" != 0 ]; then
  echo "Line ending test: FAILURE"
  ((ERROR_COUNT++))
else
  echo "Line ending test: PASS"
fi
echo

# Check coding style

echo 'Checking coding style compliance...'
echo
if [ "$IS_CONTINUOUS_INTEGRATION" == 1 ]; then
    "$CI_ROOT"/script/static-checks/static-checks-coding-style.sh
else
    "$CI_ROOT"/script/static-checks/static-checks-coding-style-entire-src-tree.sh
fi
if [ "$?" != 0 ]; then
  echo "Coding style test: FAILURE"
  ((ERROR_COUNT++))
else
  echo "Coding style test: PASS"
fi
echo

# Check for any Banned API usage

echo 'Checking Banned API usage...'
echo
if [ "$IS_CONTINUOUS_INTEGRATION" == 1 ]; then
    "$CI_ROOT"/script/static-checks/static-checks-banned-apis.sh . patch
else
    "$CI_ROOT"/script/static-checks/static-checks-banned-apis.sh
fi
if [ "$?" != 0 ]; then
  echo "Banned API check: FAILURE"
  ((ERROR_COUNT++))
else
  echo "Banned API check: PASS"
fi
echo


# Check error count

if [ "$ERROR_COUNT" != 0 ] || [ "$WARNING_COUNT" != 0 ]; then
  echo "Some static checks have failed."
fi

if [ "$ERROR_COUNT" != 0 ]; then
  exit 1
fi

exit 0
