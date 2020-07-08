#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

TEST_CASE="cppcheck to the entire source tree"

echo "# cppcheck to the entire source tree"

TF_BASE="$(pwd)"

export LOG_TEST_FILENAME=$(pwd)/static-checks-cppcheck.log

# cppcheck configuration
COMMON_ARGS=(-j 16 -q -f --std=c99 --error-exitcode=1 --relative-paths="$TF_BASE")
CHECKS_ARGS=(--enable=warning,style,portability)
SUPPRESSIONS=(--suppress=variableScope)

# Excluded directories
EXCLUDES=(
plat/hisilicon
plat/mediatek
plat/nvidia
plat/qemu
plat/rockchip
plat/socionext
plat/xilinx
)

do_lint()
{
  local EXCLUDED_DIRS=()
  local HDR_INCS=()

  LOG_FILE=$(mktemp -t cppcheck_log.XXXX)

  # Build a list of excluded directories
  for exc in "${EXCLUDES[@]}"; do
    EXCLUDED_DIRS+=(-i "$exc")
  done

  while read -r dir; do
    HDR_INCS+=(-I "$dir")
  done < <(find "$TF_BASE" -name "*.h" -exec dirname {} \; | sort -u)

  cppcheck \
    "${COMMON_ARGS[@]}" \
    "${CHECKS_ARGS[@]}" \
    "${HDR_INCS[@]}" \
    "${SUPPRESSIONS[@]}" \
    "${EXCLUDED_DIRS[@]}" "$TF_BASE" &> "$LOG_FILE"
  EXIT_VALUE="$?"

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

  rm -f "$LOG_FILE"

  exit "$EXIT_VALUE"
}

do_lint
