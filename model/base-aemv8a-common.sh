#!/bin/bash
#
# Copyright (c) 2019, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

reset_var cluster_0_has_el2
reset_var cluster_1_has_el2

reset_var cluster_0_reg_reset
reset_var cluster_1_reg_reset

reset_var cluster_0_num_cores
reset_var cluster_1_num_cores

reset_var aarch64_only
reset_var aarch32

reset_var gicv3_gicv2_only

reset_var sve_plugin

source "$ci_root/model/fvp_common.sh"

cat <<EOF >>"$model_param_file"

${cluster_0_reg_reset+-C cluster0.register_reset_data=$cluster_0_reg_reset}
${cluster_1_reg_reset+-C cluster1.register_reset_data=$cluster_1_reg_reset}

${cluster_0_has_el2+-C cluster0.has_el2=$cluster_0_has_el2}
${cluster_1_has_el2+-C cluster1.has_el2=$cluster_1_has_el2}

${reset_to_bl31+-C cluster0.cpu0.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster0.cpu1.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster0.cpu2.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster0.cpu3.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu0.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu1.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu2.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu3.RVBAR=${bl31_addr:?}}

${reset_to_spmin+-C cluster0.cpu0.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster0.cpu1.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster0.cpu2.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster0.cpu3.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu0.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu1.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu2.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu3.RVBAR=${bl32_addr:?}}

${cluster_0_num_cores+-C cluster0.NUM_CORES=$cluster_0_num_cores}
${cluster_1_num_cores+-C cluster1.NUM_CORES=$cluster_1_num_cores}

${el3_payload_bin+--data cluster0.cpu0=$el3_payload_bin@${el3_payload_addr:?}}

${aarch64_only+-C cluster0.max_32bit_el=-1}
${aarch64_only+-C cluster1.max_32bit_el=-1}

${aarch32+-C cluster0.cpu0.CONFIG64=0}
${aarch32+-C cluster0.cpu1.CONFIG64=0}
${aarch32+-C cluster0.cpu2.CONFIG64=0}
${aarch32+-C cluster0.cpu3.CONFIG64=0}
${aarch32+-C cluster1.cpu0.CONFIG64=0}
${aarch32+-C cluster1.cpu1.CONFIG64=0}
${aarch32+-C cluster1.cpu2.CONFIG64=0}
${aarch32+-C cluster1.cpu3.CONFIG64=0}

${gicv3_gicv2_only+-C gicv3.gicv2-only=$gicv3_gicv2_only}

${sve_plugin+--plugin=$sve_plugin_path}
${sve_plugin+-C SVE.ScalableVectorExtension.enable_at_reset=0}
${sve_plugin+-C SVE.ScalableVectorExtension.veclen=$((128 / 8))}

${bl2_at_el3+-C cluster0.cpu0.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster0.cpu1.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster0.cpu2.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster0.cpu3.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu0.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu1.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu2.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu3.RVBAR=${bl2_addr:?}}
EOF

# Parameters to select architecture version
if [ "$arch_version" = "8.3" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.has_arm_v8-3=1
-C cluster1.has_arm_v8-3=1
EOF
fi

if [ "$arch_version" = "8.4" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.has_arm_v8-4=1
-C cluster1.has_arm_v8-4=1
EOF
fi

# Parameters for fault injection
if [ "$fault_inject" = "1" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.number_of_error_records=2
-C cluster1.number_of_error_records=2
-C cluster0.has_ras=2
-C cluster1.has_ras=2

-C cluster0.error_record_feature_register='{"INJ":0x1,"ED":0x1,"UI":0x0,"FI":0x0,"UE":0x1,"CFI":0x0,"CEC":0x0,"RP":0x0,"DUI":0x0,"CEO":0x0}'
-C cluster1.error_record_feature_register='{"INJ":0x1,"ED":0x1,"UI":0x0,"FI":0x0,"UE":0x1,"CFI":0x0,"CEC":0x0,"RP":0x0,"DUI":0x0,"CEO":0x0}'
-C cluster0.pseudo_fault_generation_feature_register='{"UC":true,"UEU":true,"UER":false,"UEO":false,"DE":false,"CE":false,"R":false}'
-C cluster1.pseudo_fault_generation_feature_register='{"UC":true,"UEU":true,"UER":false,"UEO":false,"DE":false,"CE":false,"R":false}'
EOF
fi
