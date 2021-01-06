#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#
set terminal png enhanced font ",18" size 1920, 1080
set style data histograms
set style histogram rowstacked
set boxwidth 0.5 relative
set style fill solid 1.0 border -1
set title "Incremental Tests Enabled at each CI level for ".subtitle
plot ARG1 using 2:xtic(1) title "Build-only",\
	  '' using 3 title "Static (MISRA, etc.)",\
	  '' using 4 title "Component",\
	  '' using 5 title "Integration (boot Linux, etc.)"
