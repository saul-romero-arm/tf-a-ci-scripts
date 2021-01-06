#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#!/usr/bin/env bash
set -euo pipefail

# This script plots the categories of tests by group. It does this by combining
# the awk script and gnuplot script of the same name. This script accepts an
# argument, in the format of a grep expression, that allows the tests to be
# filtered before categorization. This script produces the plot as a png on
# stdout.

# Variables
# ^^^^^^^^^
#
# We are located in a specific location with this repo, so we can take
# advantage of that to avoid any issues with running this from an unexpected
# directory.
rootdir=$(realpath $(dirname $(realpath $0))/../..)

# I would like to use process-substitution for this, so that we can avoid
# making a file on disk and keep everything in memory, removing the need to
# clean anything up on exit and preventing any chance of polluting the user's
# filesystem. However, when gnuplot is asked to plot from the same file more
# than once, it will seek to the start of the file for every subsequent plot
# after the first. Unix Pipes do not support this operation, and plotting fails
# under these circumstances. Instead, we use an intermediate file, which is
# removed on success.
categories=$(mktemp "XXXXXXX-test-categories.dat")

# We change a portion of the title for our graph based on the argument passed
# to this script.
title=$(if [[ $# -ge 1 ]] ; then echo $1 ; else echo "All Tests" ; fi)

# Generate Data into the $categories file
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#
# The following pipeline is the heart of the implementation, and has four
# stages: find, ???, awk, and sort. The ??? stage of the pipeline is determined
# by the bash if statement, which switches between a filter, when an argument
# is passed, and a passthrough, implemented as `cat -`, when no filter
# argument is passed.
#
# Note that the env -C before the find is to enforce that it produces
# directories relative to the $rootdir, so that it does not trip up the awk
# script.
env -C $rootdir find group -type f |\
	if [[ $# -ge 1 ]] ; then
		grep -e "$1" -
	else
		cat -
	fi | awk -f ${0%bash}awk | sort > $categories

# Generate a Plot (on stdout)
gnuplot -e "subtitle='$title'" -c ${0%bash}plot $categories

# Dump data to stderr
echo name build static component inegration 1>&2
cat $categories 1>&2

# Clean up temporary files
rm $categories
