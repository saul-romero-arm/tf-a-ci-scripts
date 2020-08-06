#!/usr/bin/env bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# Run Coverity on a source tree.
# Then:
# - either produce a tarball ready to be submitted to Coverity Scan Online
#   [online mode]
# - or locally analyze and create a text report and HTML pages of the analysis
#   [offline mode]
#
# The following arguments must be passed to this script:
# 1. The command to use to build the software (this can be a script).
# 2. The mode: "online" or "offline".
# 3. The name of the output file to produce.
#    In the online mode, this should be a tarball name.
#    In the offline mode, this should be a text file name.
# 4. In the offline mode, the path to the source tree to analyze.
#
# Assumptions:
# The following tools are loaded in the PATH:
#  - the Coverity tools (cov-configure, cov-build, and so on);
#  - the AArch64 cross-toolchain;
#  - the AArch32 cross-toolchain.

# Bail out as soon as an error is encountered
set -e


function do_check_tools()
{
    local mode="$1"

    echo
    echo "Checking all required tools are available..."
    echo

    # Print version of the Coverity tools.
    # This also serves as a check that the tools are available.
    cov-configure --ident
    cov-build --ident
    if [[ "$mode" == "offline" ]]; then
	cov-analyze --ident
    fi

    # Check that the AArch64 cross-toolchain is available.
    aarch64-none-elf-gcc --version

    # Check that the AArch32 cross-toolchain is available.
    arm-none-eabi-gcc --version

    echo
    echo "Checks complete."
    echo
}


function do_configure()
{
    # Create Coverity's configuration directory and its intermediate directory.
    rm -rf cov-config cov-int
    mkdir cov-config cov-int

    # Generate Coverity's configuration files.
    #
    # This needs to be done for each compiler.
    # Each invocation of the cov-configure command adds a compiler configuration in
    # its own subdirectory, and the top XML configuration file contains an include
    # directive for that compiler-specific configuration.
    #   1) AArch64 compiler
    cov-configure				\
	--comptype gcc				\
	--template				\
	--compiler aarch64-none-elf-gcc	\
	--config cov-config/config.xml
    #   2) AArch32 compiler
    cov-configure				\
	--comptype gcc				\
	--template				\
	--compiler arm-none-eabi-gcc			\
	--config cov-config/config.xml
}


function do_build()
{
    local build_cmd=("$*")

    echo
    echo "* The software will be built using the following command line:"
    echo "$build_cmd"
    echo

    # Build the instrumented binaries.
    cov-build				\
	--config cov-config/config.xml	\
	--dir cov-int			\
	$build_cmd

    echo
    echo "Build complete."
    echo
}


function do_analyze()
{
    local out="$1"
    local src_tree="$2"
    local profile="$3"
    out="${profile}_${out}"

    echo
    echo "Starting the local analysis..."
    echo "  (Profile: $profile)"
    echo
    echo "The results will be saved into '$out'."
    echo

    results_dir=$(pwd)
    cd "$src_tree"

    # Analyze the instrumented binaries.
    # Get the analysis settings from the right profile file.
    cov-analyze							\
	$(cat $(dirname "$0")/coverity_profile_${profile})	\
	${analysis_settings[@]}					\
	--dir "$results_dir/cov-int"				\
	--verbose 0						\
	--redirect stdout,"$results_dir/$out"

    # Generate HTML pages
    cov-format-errors						\
	--html-output "$results_dir/results/html/${profile}"	\
	--filesort						\
	--dir "$results_dir/cov-int"

    # Generate text report
    mkdir -p "$results_dir/results/text"
    cov-format-errors					\
	--emacs-style					\
	--filesort					\
	--dir "$results_dir/cov-int"			\
	> "$results_dir/results/text/${profile}"
    cd -
    echo "Analysis complete."
}


function create_results_tarball()
{
    local tarball_name="$1"

    echo
    echo "Creating the tarball containing the results of the analysis..."
    echo
    tar -czvf "$tarball_name" cov-int/
    echo
    echo "Complete."
    echo
}


###############################################################################
PHASE="$1"
echo "Coverity: phase '$PHASE'"
shift

case $PHASE in
    check_tools)
	ANALYSIS_MODE="$1"
	do_check_tools "$ANALYSIS_MODE"
    ;;

    configure)
	do_configure
    ;;

    build)
	do_build "$1"
    ;;

    analyze)
	OUTPUT_FILE="$1"
	SOURCE_TREE="$2"
	ANALYSIS_PROFILE="$3"
	do_analyze "$OUTPUT_FILE" "$SOURCE_TREE" "$ANALYSIS_PROFILE"
    ;;

    package)
	OUTPUT_FILE="$1"
	create_results_tarball "$OUTPUT_FILE"
	;;

    *)
	echo "Invalid phase '$PHASE'"
esac
