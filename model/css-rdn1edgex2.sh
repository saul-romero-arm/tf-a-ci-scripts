#!/usr/bin/env bash
#
# Copyright (c) 2020-2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set_model_path "$warehouse/SysGen/SubSystemModels/11.17/33/models/$model_flavour/FVP_RD_N1_edge_dual"

cat <<EOF >"$model_param_file"

-C board0.flashloader0.fname=$fip_bin
-C css0.cmn600.force_rnsam_internal=false
-C css0.cmn600.mesh_config_file=RD_N1_E1_cmn600.yml
-C css0.gic_distributor.ITS-device-bits=20
-C css0.gic_distributor.multichip-threaded-dgi=0
-C css0.mcp.ROMloader.fname=$mcp_rom_bin
-C css0.pl011_uart_ap.unbuffered_output=1
-C css0.scp.pl011_uart_scp.unbuffered_output=1
-C css0.scp.ROMloader.fname=$scp_rom_bin
-C css0.trustedBootROMloader.fname=$bl1_bin
-C css1.cmn600.force_rnsam_internal=false
-C css1.cmn600.mesh_config_file=RD_N1_E1_cmn600.yml
-C css1.gic_distributor.ITS-device-bits=20
-C css1.gic_distributor.multichip-threaded-dgi=0
-C css1.mcp.ROMloader.fname=$mcp_rom_bin
-C css1.pl011_uart_ap.unbuffered_output=1
-C css1.scp.pl011_uart_scp.unbuffered_output=1
-C css1.scp.ROMloader.fname=$scp_rom_bin
-C css1.trustedBootROMloader.fname=$bl1_bin
-C soc0.pl011_uart_mcp.unbuffered_output=1
-C soc0.pl011_uart0.enable_dc4=0
-C soc0.pl011_uart0.flow_ctrl_mask_en=1
-C soc0.pl011_uart0.unbuffered_output=1
-C soc0.pl011_uart1.unbuffered_output=1
-C soc1.pl011_uart_mcp.unbuffered_output=1
-C soc1.pl011_uart0.unbuffered_output=1
-C soc1.pl011_uart1.unbuffered_output=1

--data css0.scp.armcortexm7ct=$scp_ram_bin@$scp_ram_addr
--data css1.scp.armcortexm7ct=$scp_ram_bin@$scp_ram_addr
EOF
