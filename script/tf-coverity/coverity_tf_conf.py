#
# Copyright (c) 2019-2021, Arm Limited. All rights reserved.
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
    ("drivers/scmi-msg/power_domain.c", "Not used by any upstream platform"),

    ("plat/arm/board/fvp/fconf/fconf_nt_config_getter.c", "Not currently used. Future functionality"),
    ("plat/marvell/armada/a8k/common/plat_bl1_setup.c", "Not used by any upstream marvell platform"),
    ("plat/mediatek/common/custom/oem_svc.c", "Used only by mt6795 which is unsupported platform"),
    ("plat/mediatek/mt6795/.*", "This platform fails to build and is not supported by mediatek"),
    ("plat/mediatek/mt8173/plat_mt_gic.c", "Deprecated code"),
    ("plat/nvidia/tegra/common/tegra_gicv3.c", "Not used by any upstream nvidia platform"),
    ("plat/qemu/common/sp_min/sp_min_setup.c", "Not used in any upstream platform - see GENFW-2164"),
    ("plat/rockchip/rk3399/drivers/m0/.*", "Work around the lack of support for the M0 compiler in the scripts"),
    ("drivers/arm/gic/v3/gic600ae_fmu.c", "Not used by any upstream platform"),
    ("drivers/arm/gic/v3/gic600ae_fmu_helpers.c", "Not used by any upstream platform"),

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
    ("drivers/nxp/console/console_16550.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/csu/csu.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/ddr/fsl-mmdc/fsl_mmdc.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/ddr/phy-gen1/phy.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/gic/ls_gicv2.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/gpio/nxp_gpio.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/interconnect/ls_cci.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/qspi/qspi.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/sfp/fuse_prov.c", "Cannot be built due to external dependencies"),
    ("drivers/nxp/sfp/sfp.c", "Cannot be built due to external dependencies"),
    ("plat/nxp/common/fip_handler/fuse_fip/fuse_io_storage.c", "Cannot be built due to external dependencies"),

    ("lib/compiler-rt/.*", "3rd party libraries will not be fixed"),
    ("lib/libfdt/.*", "3rd party libraries will not be fixed"),
    ("lib/libc/strlcat.c", "Not used by any upstream platform"),
    ("lib/libc/strtok.c", "Not used by any upstream platform"),

    ("tools/.*", "Host tools"),

    # Temporarily exclude the following files such that tf-coverity job can be
    # reinstated. Appropriate build commands to compile these files should be
    # added to tf-cov-make script after v2.5 release
    ("drivers/arm/tzc/tzc_dmc500.c", "Temporarily excluded"),
    ("drivers/renesas/common/ddr/ddr_b/boot_init_dram_config.c", "Temporarily excluded"),
    ("drivers/renesas/rzg/pfc/G2E/pfc_init_g2e.c", "Temporarily excluded"),
    ("drivers/renesas/rzg/pfc/G2H/pfc_init_g2h.c", "Temporarily excluded"),
    ("drivers/renesas/rzg/pfc/G2N/pfc_init_g2n.c", "Temporarily excluded"),
    ("drivers/renesas/rzg/qos/G2E/qos_init_g2e_v10.c", "Temporarily excluded"),
    ("drivers/renesas/rzg/qos/G2H/qos_init_g2h_v30.c", "Temporarily excluded"),
    ("drivers/renesas/rzg/qos/G2N/qos_init_g2n_v10.c", "Temporarily excluded"),
    ("plat/arm/board/sgm775/sgm775_err.c", "Temporarily excluded"),
    ("plat/arm/board/sgm775/sgm775_trusted_boot.c", "Temporarily excluded"),
    ("plat/arm/common/arm_tzc_dmc500.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_bl1_setup.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_bl31_setup.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_interconnect.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_mmap_config.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_plat_config.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_security.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/sgm_topology.c", "Temporarily excluded"),
    ("plat/arm/css/sgm/tsp/sgm_tsp_setup.c", "Temporarily excluded"),
    ("plat/brcm/board/stingray/driver/usb.c", "Temporarily excluded"),
    ("plat/brcm/board/stingray/driver/usb_phy.c", "Temporarily excluded"),
    ("plat/imx/imx8m/imx8mm/imx8mm_bl2_el3_setup.c", "Temporarily excluded"),
    ("plat/imx/imx8m/imx8mm/imx8mm_bl2_mem_params_desc.c", "Temporarily excluded"),
    ("plat/imx/imx8m/imx8mm/imx8mm_image_load.c", "Temporarily excluded"),
    ("plat/imx/imx8m/imx8mm/imx8mm_io_storage.c", "Temporarily excluded"),
    ("plat/imx/imx8m/imx8mm/imx8mm_trusted_boot.c", "Temporarily excluded"),
    ("plat/marvell/armada/a3k/a3700/board/pm_src.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/aarch64/platform_common.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/bl31_plat_setup.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/dp/mt_dp.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/gpio/mtgpio.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/mcdi/mt_cpu_pm.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/mcdi/mt_cpu_pm_cpc.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/mcdi/mt_mcdi.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/pmic/pmic.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/drivers/spmc/mtspmc.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/plat_pm.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/plat_sip_calls.c", "Temporarily excluded"),
    ("plat/mediatek/mt8195/plat_topology.", "Temporarily excluded"),

    # Exclude the following files of imx8mq as this platform is dropped
    # from the CI. Put the files of this platform into a silent status.
    ("plat/imx/imx8m/imx8mq/gpc.c", "Not currently used"),
    ("plat/imx/imx8m/imx8mq/imx8mq_bl31_setup.c", "Not currently used"),
    ("plat/imx/imx8m/imx8mq/imx8mq_psci.c", "Not currently used"),
]
