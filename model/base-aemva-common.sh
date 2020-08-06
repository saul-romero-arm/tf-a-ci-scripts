#!/bin/bash
#
# Copyright (c) 2019-2020, Arm Limited. All rights reserved.
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

#------------ GIC configuration --------------

# GICv2 compatibility is not supported and GICD_CTLR.ARE_* is always one
reset_var gicd_are_fixed_one

# Number of extended PPI supported: Default 0, Maximum 64
reset_var gicd_ext_ppi_count

# Number of extended SPI supported: Default 0, Maximum 1024
reset_var gicd_ext_spi_count

# Number of Interrupt Translation Services to be instantiated (0=none)
reset_var gicd_its_count

# GICv4 Virtual LPIs and Direct injection of Virtual LPIs supported
reset_var gicd_virtual_lpi

# Device has support for extended SPI/PPI ID ranges
reset_var gicv3_ext_interrupt_range

# When using the GICv3 model, pretend to be a GICv2 system
reset_var gicv3_gicv2_only

# Number of SPIs that are implemented: Default 224, Maximum 988
reset_var gicv3_spi_count

# Enable GICv4.1 functionality
reset_var has_gicv4_1

reset_var sve_plugin

reset_var bmcov_plugin

reset_var retain_flash

reset_var nvcounter_version
reset_var nvcounter_diag

source "$ci_root/model/fvp_common.sh"

#------------ Common configuration --------------

cat <<EOF >>"$model_param_file"
${gicv3_gicv2_only+-C gicv3.gicv2-only=$gicv3_gicv2_only}
${gicv3_spi_count+-C gic_distributor.SPI-count=$gicv3_spi_count}
${gicd_are_fixed_one+-C gic_distributor.ARE-fixed-to-one=$gicd_are_fixed_one}
${gicd_ext_ppi_count+-C gic_distributor.extended-ppi-count=$gicd_ext_ppi_count}
${gicd_ext_spi_count+-C gic_distributor.extended-spi-count=$gicd_ext_spi_count}
${gicd_its_count+-C gic_distributor.ITS-count=$gicd_its_count}
${gicd_virtual_lpi+-C gic_distributor.virtual-lpi-support=$gicd_virtual_lpi}
${has_gicv4_1+-C has-gicv4.1=$has_gicv4_1}

${sve_plugin+--plugin=$sve_plugin_path}
${sve_plugin+-C SVE.ScalableVectorExtension.enable_at_reset=0}
${sve_plugin+-C SVE.ScalableVectorExtension.veclen=$((128 / 8))}

${bmcov_plugin+--plugin=$bmcov_plugin_path}

${nvcounter_version+-C bp.trusted_nv_counter.version=$nvcounter_version}
${nvcounter_diag+-C bp.trusted_nv_counter.diagnostics=$nvcounter_diag}
EOF

# TFTF Reboot/Shutdown tests
if [ "$retain_flash" = "1" ]; then
	cat <<EOF >>"$model_param_file"
-C bp.flashloader1.fname=$flashloader1_fwrite
-C bp.flashloader1.fnameWrite=$flashloader1_fwrite
-C bp.flashloader0.fnameWrite=$flashloader0_fwrite
-C bp.pl011_uart0.untimed_fifos=1
-C bp.ve_sysregs.mmbSiteDefault=0
EOF
fi

#------------ Cluster0 configuration --------------

cat <<EOF >>"$model_param_file"
${cluster_0_reg_reset+-C cluster0.register_reset_data=$cluster_0_reg_reset}

${cluster_0_has_el2+-C cluster0.has_el2=$cluster_0_has_el2}

${amu_present+-C cluster0.has_amu=$amu_present}

${reset_to_bl31+-C cluster0.cpu0.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster0.cpu1.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster0.cpu2.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster0.cpu3.RVBAR=${bl31_addr:?}}

${reset_to_spmin+-C cluster0.cpu0.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster0.cpu1.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster0.cpu2.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster0.cpu3.RVBAR=${bl32_addr:?}}

${cluster_0_num_cores+-C cluster0.NUM_CORES=$cluster_0_num_cores}

${el3_payload_bin+--data cluster0.cpu0=$el3_payload_bin@${el3_payload_addr:?}}

${aarch64_only+-C cluster0.max_32bit_el=-1}

${aarch32+-C cluster0.cpu0.CONFIG64=0}
${aarch32+-C cluster0.cpu1.CONFIG64=0}
${aarch32+-C cluster0.cpu2.CONFIG64=0}
${aarch32+-C cluster0.cpu3.CONFIG64=0}


${bl2_at_el3+-C cluster0.cpu0.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster0.cpu1.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster0.cpu2.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster0.cpu3.RVBAR=${bl2_addr:?}}

${memory_tagging_support_level+-C cluster0.memory_tagging_support_level=$memory_tagging_support_level}

${gicv3_ext_interrupt_range+-C cluster0.gicv3.extended-interrupt-range-support=$gicv3_ext_interrupt_range}
EOF

# Parameters to select architecture version
if [ "$arch_version" = "8.3" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.has_arm_v8-3=1
EOF
fi

if [ "$arch_version" = "8.4" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.has_arm_v8-4=1
EOF
fi

if [ "$arch_version" = "8.5" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.has_arm_v8-5=1
EOF
fi

if [ "$arch_version" = "8.6" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.has_arm_v8-6=1
EOF
fi

# Parameters for fault injection
if [ "$fault_inject" = "1" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster0.number_of_error_records=2
-C cluster0.has_ras=2
-C cluster0.error_record_feature_register='{"INJ":0x1,"ED":0x1,"UI":0x0,"FI":0x0,"UE":0x1,"CFI":0x0,"CEC":0x0,"RP":0x0,"DUI":0x0,"CEO":0x0}'
-C cluster0.pseudo_fault_generation_feature_register='{"OF":false,"CI":false,"ER":false,"PN":false,"AV":false,"MV":false,"SYN":false,"UC":true,"UEU":true,"UER":false,"UEO":false,"DE":false,"CE":0,"R":false}'
EOF
fi

#------------ Cluster1 configuration (if exists) --------------
if [ "$is_dual_cluster" = "1" ]; then
	cat <<EOF >>"$model_param_file"
${cluster_1_reg_reset+-C cluster1.register_reset_data=$cluster_1_reg_reset}

${cluster_1_has_el2+-C cluster1.has_el2=$cluster_1_has_el2}

${amu_present+-C cluster1.has_amu=$amu_present}

${reset_to_bl31+-C cluster1.cpu0.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu1.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu2.RVBAR=${bl31_addr:?}}
${reset_to_bl31+-C cluster1.cpu3.RVBAR=${bl31_addr:?}}

${reset_to_spmin+-C cluster1.cpu0.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu1.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu2.RVBAR=${bl32_addr:?}}
${reset_to_spmin+-C cluster1.cpu3.RVBAR=${bl32_addr:?}}

${cluster_1_num_cores+-C cluster1.NUM_CORES=$cluster_1_num_cores}

${aarch64_only+-C cluster1.max_32bit_el=-1}

${aarch32+-C cluster1.cpu0.CONFIG64=0}
${aarch32+-C cluster1.cpu1.CONFIG64=0}
${aarch32+-C cluster1.cpu2.CONFIG64=0}
${aarch32+-C cluster1.cpu3.CONFIG64=0}

${bl2_at_el3+-C cluster1.cpu0.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu1.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu2.RVBAR=${bl2_addr:?}}
${bl2_at_el3+-C cluster1.cpu3.RVBAR=${bl2_addr:?}}

${memory_tagging_support_level+-C cluster1.memory_tagging_support_level=$memory_tagging_support_level}

${gicv3_ext_interrupt_range+-C cluster1.gicv3.extended-interrupt-range-support=$gicv3_ext_interrupt_range}
EOF

# Parameters to select architecture version
if [ "$arch_version" = "8.3" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster1.has_arm_v8-3=1
EOF
fi

if [ "$arch_version" = "8.4" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster1.has_arm_v8-4=1
EOF
fi

if [ "$arch_version" = "8.5" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster1.has_arm_v8-5=1
EOF
fi

if [ "$arch_version" = "8.6" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster1.has_arm_v8-6=1
EOF
fi

# Parameters for fault injection
if [ "$fault_inject" = "1" ]; then
	cat <<EOF >>"$model_param_file"
-C cluster1.number_of_error_records=2
-C cluster1.has_ras=2
-C cluster1.error_record_feature_register='{"INJ":0x1,"ED":0x1,"UI":0x0,"FI":0x0,"UE":0x1,"CFI":0x0,"CEC":0x0,"RP":0x0,"DUI":0x0,"CEO":0x0}'
-C cluster1.pseudo_fault_generation_feature_register='{"OF":false,"CI":false,"ER":false,"PN":false,"AV":false,"MV":false,"SYN":false,"UC":true,"UEU":true,"UER":false,"UEO":false,"DE":false,"CE":0,"R":false}'
EOF
fi
fi