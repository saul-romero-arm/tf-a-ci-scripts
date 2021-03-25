#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/SubSystemModels/11.10/36/models/Linux64_GCC-6.4/FVP_RD_N1_edge_dual"

cat <<EOF >"$model_param_file"
-C css0.cmn600.force_on_from_start=1
-C css0.cmn600.mesh_config_file=RD_N1_E1_cmn600_ccix.yml
-C css0.mcp.ROMloader.fname=$mcp_rom_bin
-C css0.scp.ROMloader.fname=$scp_rom_bin
--data css0.scp.armcortexm7ct=$scp_ram_bin@$scp_ram_addr
-C css0.trustedBootROMloader.fname=$bl1_bin
-C board0.flashloader0.fname=$fip_bin
-C board0.virtioblockdevice.image_path=$busybox_bin
-C css0.pl011_uart_ap.unbuffered_output=1
-C soc0.pl011_uart0.unbuffered_output=1
-C soc0.pl011_uart1.unbuffered_output=1

-C css1.cmn600.force_on_from_start=1
-C css1.cmn600.mesh_config_file=RD_N1_E1_cmn600_ccix.yml
-C css1.mcp.ROMloader.fname=$mcp_rom_bin
-C css1.scp.ROMloader.fname=$scp_rom_bin
--data css1.scp.armcortexm7ct=$scp_ram_bin@$scp_ram_addr
-C css1.pl011_uart_ap.unbuffered_output=1
EOF
