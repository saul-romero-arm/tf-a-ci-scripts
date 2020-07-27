#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

#
# This file lists the source files that are expected to be excluded from
# Coverity's analysis, and the reason why.
#

# The expected format is an array of tuples (filename_pattern, description).
# - filename_pattern is a Python regular expression (as in the 're' module)
#   describing the file(s) to exclude.
# - description aims at providing the reason why the files are expected
#   to be excluded.
exclude_paths = [
    ("drivers/arm/cci400/cci400.c", "deprecated driver"),
    ("drivers/arm/gic/v3/arm_gicv3_common.c", "platform to exercise GIC-500/600 powerdown not available yet"),
    ("drivers/arm/tzc400/tzc400.c", "deprecated driver"),
    ("drivers/arm/tzc/tzc_common_private.c",
     "file included, actually indirectly analyzed"),
    ("drivers/arm/tzc/tzc_dmc500.c", "not used by any upstream platform"),

    ("drivers/io/io_dummy.c", "not used by any upstream platform"),
    ("drivers/partition/gpt.c", "not used by any upstream platform"),
    ("drivers/partition/partition.c", "not used by any upstream platform"),

    ("lib/aarch64/xlat_tables.c", "deprecated library code"),

    ("plat/arm/board/fvp/fconf/fconf_nt_config_getter.c", "Not currently used. Future functionality"),
    ("plat/arm/common/arm_tzc_dmc500.c", "not used by any upstream platform"),

    ("plat/mediatek/mt8173/plat_mt_gic.c", "deprecated code"),

    ("lib/aarch32/arm32_aeabi_divmod.c", "not used by any upstream platform"),

    # Waiting for the following patch to be available:
    # http://ssg-sw.cambridge.arm.com/gerrit/#/c/49862/
    ("plat/rockchip/rk3399/drivers/m0/.*",
     "work around the lack of support for the M0 compiler in the scripts"),

    ("tools/.*", "Host tools"),
    ("plat/qemu/sp_min/sp_min_setup.c", "not used in any upstream platform - see GENFW-2164")
]
