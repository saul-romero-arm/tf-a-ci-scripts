#
# Copyright (c) 2021-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set title "Source Lines of Code by Module"
set terminal png enhanced font ",16" size 1920, 1080

set datafile separator tab

set key autotitle columnheader
set key reverse Left outside

set xtics nomirror rotate by -75 scale 0

set style data histogram
set style histogram rowstacked
set style fill solid border -1

set boxwidth 0.75

set lt 1 lc rgb "#C971B2"
set lt 2 lc rgb "#78D19F"
set lt 3 lc rgb "#CB9B6B"
set lt 4 lc rgb "#7696C0"
set lt 5 lc rgb "#ECEAC6"
set lt 6 lc rgb "#D2CCDA"
set lt 7 lc rgb "#766AC9"
set lt 8 lc rgb "#C86D6A"
set lt 9 lc rgb "#92CCD7"
set lt 10 lc rgb "#DEAAB5"
set lt 11 lc rgb "#BC9FD9"
set lt 12 lc rgb "#A5B08B"

stats ARG1 matrix rowheader columnheader nooutput

plot ARG1 using 2:xtic(1), for [i=3:(STATS_columns + 1)] "" using i
