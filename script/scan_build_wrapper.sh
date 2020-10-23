#!/usr/bin/env bash
#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

scan_build_wrapper(){

	local make_command="$(echo $@)"
	local cross_compile="$(grep -oP "(?<=CROSS_COMPILE=)[a-z\-0-9]+" <<< $make_command)"
	local build_config="$(echo $make_command | awk 'BEGIN {FS = "make "}{print $2}')"
	local scan_build_flags="-v -analyze-headers -analyzer-config stable-report-filename=true "

	# scan_build generates html and .js files to render bugs on code base
	reports_dir="$workspace/scan-build-reports/"

	# Get approprtiate compiler path
	scan_build_flags+=" -o $reports_dir --use-cc=$(which ${cross_compile}gcc) \
				--analyzer-target=${cross_compile}"

	# Workaround a limiation in jenkins arch-dev nodes
	if [ "$JENKINS_HOME" ]; then
		export PATH=/usr/lib/llvm-6.0/bin/:$PATH
		echo_w "Jenkins runs"
		scan_build_artefacts="$BUILD_URL/artifact/artefacts/debug/scan-build-reports"
	else
		echo_w "Local runs"
		scan_build_artefacts="$artefacts/debug/scan-build-reports"
	fi

	echo_w "Build config selected: $tf_config"
	make realclean

	local build_info=$(scan-build ${scan_build_flags} $make_command)
	result_loc=$(echo $build_info | awk 'BEGIN {FS = "scan-view "}{print $2}' \
			| awk 'BEGIN {FS = " to examine bug reports"}{print $1}' \
			| awk '{ gsub("[:\47]" , ""); print $0}')

	if [ -d $result_loc ]; then
		local defects="$(find $result_loc -iname 'report*.html'| wc -l)"
		if [ $defects -ge 1 ]; then
			echo_w "$defects defect(s) found in build \"$build_config\" "
			echo_w "Please view the detailed report here:"
			echo_w "$scan_build_artefacts/$tf_config-reports/index.html"
		fi
		mv "$result_loc" "$reports_dir/$tf_config-reports"
	fi
}
