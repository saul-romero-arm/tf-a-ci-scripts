#!/usr/bin/env bash
#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# static-checks-detect-newly-added-files.sh
# This script aims at identifying the newly added source files
# between the commits.
# It runs on every TF-A patch and detects the new files and updates
# the patch contibutor to include them for Coverity Scan analysis.

LOG_FILE=$(mktemp -t files-detection-check.XXXX)
TFA_PATCH_NEWFILES_LIST=$(mktemp -t tfa-patch-newfiles-list.XXXX)
EXIT_VALUE=0

# Function    : file_updation_report
# Description : To update the inclusion of files listed in the temp file
#               (tfa-patch-newfiles-list.XXXX) for Coverity Scan Analysis.
# Return      : newly added source files,are captured onto the error log
#				and the Error status is printed.
function file_updation_report( )
{
  echo "========================================================================"
  echo "New source files have been identified in your patch.."
  echo >> "$LOG_FILE"
  echo "New source files have been identified in your patch.." >> "$LOG_FILE"
# Iterating through the patch filenames and logging them onto error report.
  while read filename
  do
  	echo "$filename"
    echo "$filename" >> "$LOG_FILE"
  done < "$TFA_PATCH_NEWFILES_LIST"

  echo
  echo -e "1. Kindly ensure they are updated in the \"tf-cov-make\" build script as \n \
well to consider them for Coverity Scan analysis."
  echo >> "$LOG_FILE"
  echo -e "1. Kindly ensure they are updated in the \"tf-cov-make\" build script as \n \
well to consider them for Coverity Scan analysis." >> "$LOG_FILE"

  echo
  echo -e "2. Please ignore if files are already updated. Further the Code Maintainer \n \
will resolve the issue by taking appropriate action."
  echo >> "$LOG_FILE"
  echo -e "2. Please ignore if files are already updated. Further the Code Maintainer \n \
will resolve the issue by taking appropriate action." >> "$LOG_FILE"
  echo "========================================================================"

  EXIT_VALUE=1
}

# Detecting source files not analysed by tf-coverity-job in the latest patch.
  echo "# Check to detect whether newly added files are analysed by Coverity in the patch"
  TEST_CASE="Newly added files detection check for Coverity Scan analysis on patch(es)"
# Extracting newly added source files added between commits.
  git diff origin/integration...HEAD --name-only --diff-filter=A "*.c" &> "$TFA_PATCH_NEWFILES_LIST"
  if [ -s "$TFA_PATCH_NEWFILES_LIST" ]
  then
    file_updation_report
  fi

echo >> "$LOG_TEST_FILENAME"
echo "****** $TEST_CASE ******" >> "$LOG_TEST_FILENAME"
echo >> "$LOG_TEST_FILENAME"

if [[ "$EXIT_VALUE" == 0 ]]; then
  echo "Result : SUCCESS" >> "$LOG_TEST_FILENAME"
else
  echo "Result : FAILURE" >> "$LOG_TEST_FILENAME"
fi

# Printing the script output to show the warnings.
echo >> "$LOG_TEST_FILENAME"
cat "$LOG_FILE" >> "$LOG_TEST_FILENAME"
echo >> "$LOG_TEST_FILENAME"

#Deleting temporary files
rm -f "$LOG_FILE"
rm -f "$TFA_PATCH_NEWFILES_LIST"

exit "$EXIT_VALUE"
