#
# Copyright (c) 2021-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set title "Incremental Tests Enabled at Each CI Level".subtitle
set terminal png enhanced font ",16" size 1920, 1080

set datafile separator tab
set key autotitle columnheader

set style data histograms
set style histogram rowstacked
set style fill solid border -1

set boxwidth 0.5 relative

stats ARG1 matrix rowheader columnheader nooutput

plot ARG1 using 2:xtic(1), for [i=3:(STATS_columns + 1)] "" using i
