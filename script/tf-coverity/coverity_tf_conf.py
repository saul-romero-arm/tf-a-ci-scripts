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
    ("drivers/arm/tzc/tzc_common_private.c", "File included, actually indirectly analyzed"),
    ("drivers/marvell/comphy/phy-comphy-3700.c", "File is actually analyzed. False positive"),
    ("drivers/marvell/comphy/phy-comphy-cp110.c", "File is actually analyzed. False positive"),
    ("drivers/marvell/gwin.c", "Not used by any upstream marvell platform"),
    ("drivers/marvell/mochi/ap807_setup.c", "Not used by any upstream marvell platform"),
    ("drivers/renesas/rcar/ddr/ddr_b/boot_init_dram_config.c",
     "It is used as a header file and is included in boot_init_dram.c .Since it is not explicitly compiled, such file cannot be converted into an instrumented binary for further analysis"),
    ("drivers/renesas/rzg/ddr/ddr_b/boot_init_dram_config.c",
     "It is used as a header file and is included in boot_init_dram.c .Since it is not explicitly compiled, such file cannot be converted into an instrumented binary for further analysis"),
    ("drivers/auth/cryptocell/713/.*", "There is no dummy library to support 713 for now. This can be removed once we have this library in place"),
    ("drivers/st/scmi-msg/.*", "Not used by any upstream platform"),

    ("plat/arm/board/fvp/fconf/fconf_nt_config_getter.c", "Not currently used. Future functionality"),
    ("plat/marvell/armada/a8k/common/plat_bl1_setup.c", "Not used by any upstream marvell platform"),
    ("plat/mediatek/common/custom/oem_svc.c", "Used only by mt6795 which is unsupported platform"),
    ("plat/mediatek/mt6795/.*", "This platform fails to build and is not supported by mediatek"),
    ("plat/mediatek/mt8173/plat_mt_gic.c", "Deprecated code"),
    ("plat/nvidia/tegra/common/tegra_gicv3.c", "Not used by any upstream nvidia platform"),
    ("plat/qemu/common/sp_min/sp_min_setup.c", "Not used in any upstream platform - see GENFW-2164"),
    ("plat/rockchip/rk3399/drivers/m0/.*", "Work around the lack of support for the M0 compiler in the scripts"),

    # The following block is excluding files that are impossible to include in a build due to a missing file
    # this should be removed as soon as it would be possible to build stingray platform with SCP_BL2 option
    ("drivers/brcm/iproc_gpio.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("drivers/brcm/scp.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("drivers/brcm/spi/iproc_qspi.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("drivers/brcm/spi/iproc_spi.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("drivers/brcm/spi_flash.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("drivers/brcm/spi_sf.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/board/common/bcm_elog_ddr.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/board/stingray/src/brcm_pm_ops.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/board/stingray/src/ncsi.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/board/stingray/src/scp_cmd.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/board/stingray/src/scp_utils.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/common/brcm_mhu.c", "Cannot be built due to the missing m0_ipc.h file"),
    ("plat/brcm/common/brcm_scpi.c", "Cannot be built due to the missing m0_ipc.h file"),

    # The following block is excluding files specific to NXP platforms that
    # cannot be compiled with any build flags at this moment due to external
    # dependencies
    ("drivers/nxp/auth/csf_hdr_parser/cot.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/auth/csf_hdr_parser/csf_hdr_parser.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/auth/csf_hdr_parser/plat_img_parser.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/auth/tbbr/tbbr_cot.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/console/console_16550.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/crypto/caam/src/auth/hash.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/crypto/caam/src/auth/nxp_crypto.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/crypto/caam/src/auth/rsa.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/csu/csu.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/ddr/fsl-mmdc/fsl_mmdc.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/ddr/phy-gen1/phy.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/gic/ls_gicv2.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/gpio/nxp_gpio.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/interconnect/ls_cci.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/qspi/qspi.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/sd/sd_mmc.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/sec_mon/snvs.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/sfp/fuse_prov.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/sfp/sfp.c", "Cannot be built due to external dependencies"),
    ("plat/nxp/common/fip_handler/fuse_fip/fuse_io_storage.c", "Cannot be built due to external dependencies"),
    ("plat/nxp/common/setup/ls_stack_protector.c", "Cannot be built due to external dependencies"),
    ("plat/nxp/common/tbbr/csf_tbbr.c", "Cannot be built due to external dependencies"),
    ("plat/nxp/common/tbbr/x509_tbbr.c", "Cannot be built due to external dependencies"),

    ("lib/compiler-rt/.*", "3rd party libraries will not be fixed"),
    ("lib/libfdt/.*", "3rd party libraries will not be fixed"),
    ("lib/libc/strlcat.c", "Not used by any upstream platform"),
    ("lib/libc/strtok.c", "Not used by any upstream platform"),

    ("tools/.*", "Host tools"),
]
