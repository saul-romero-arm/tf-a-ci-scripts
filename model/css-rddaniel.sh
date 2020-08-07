#!/usr/bin/env bash
#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Tell FVP to use RNSAMs as internal in CMN-Rhodes.
set_model_env "FASTSIM_CMN_INTERNAL_RNSAM" "1"

set_model_path "$warehouse/SysGen/SubSystemModels/11.10/36/models/Linux64_GCC-6.4/FVP_RD_Daniel"

cat <<EOF >"$model_param_file"
-C css.cmn_rhodes.force_on_from_start=1
-C css.mcp.ROMloader.fname=$mcp_rom_bin
-C css.scp.ROMloader.fname=$scp_rom_bin
--data css.scp.armcortexm7ct=$scp_ram_bin@$scp_ram_addr
-C css.trustedBootROMloader.fname=$bl1_bin
-C board.flashloader0.fname=$fip_bin
-C board.virtioblockdevice.image_path=$busybox_bin
-C css.pl011_uart_ap.unbuffered_output=1
-C soc.pl011_uart0.unbuffered_output=1
-C soc.pl011_uart1.unbuffered_output=1
EOF
