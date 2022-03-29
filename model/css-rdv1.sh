#!/usr/bin/env bash
#
# Copyright (c) 2020-2022, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/SubSystemModels/11.15/26/models/Linux64_GCC-6.4/FVP_RD_V1"

cat <<EOF >"$model_param_file"
-C board.flashloader0.fname=$fip_bin
-C board.virtioblockdevice.image_path=$busybox_bin
-C css.cmn_650.force_rnsam_internal=true
-C css.cmn_650.mesh_config_file=cmn650_rdv1.yml
-C css.gic_distributor.ITS-device-bits=20
-C css.mcp.ROMloader.fname=$mcp_rom_bin
-C css.pl011_uart_ap.unbuffered_output=1
-C css.scp.pl011_uart_scp.unbuffered_output=1
-C css.scp.ROMloader.fname=$scp_rom_bin
-C css.trustedBootROMloader.fname=$bl1_bin
-C soc.pl011_uart_mcp.unbuffered_output=1
-C soc.pl011_uart0.enable_dc4=0
-C soc.pl011_uart0.flow_ctrl_mask_en=1
-C soc.pl011_uart0.unbuffered_output=1
-C soc.pl011_uart1.unbuffered_output=1
--data css.scp.armcortexm7ct=$scp_ram_bin@$scp_ram_addr
--data css.mcp.armcortexm7ct=$mcp_ram_bin@$mcp_ram_addr
EOF
