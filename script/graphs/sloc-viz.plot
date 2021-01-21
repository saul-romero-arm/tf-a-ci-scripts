#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
#
# Stacked histograms
#
set terminal png enhanced font ",18" size 1920, 1080
set title "Source Lines of Code by Module"
set key invert reverse Left outside
set key autotitle columnheader
set auto y
set auto x
unset xtics
set xtics nomirror rotate by -75 scale 0
set style data histogram
set style histogram rowstacked
set style fill solid border -1
set boxwidth 0.75
#
plot ARG1 using 2:xtic(1), for [i=3:8] '' using i
#
