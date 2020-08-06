#!/usr/bin/env bash

set_model_path "$warehouse/SysGen/Models/$model_version/$model_build/models/$model_flavour/FVP_Base_Herculesx4"

# Option not supported on Hercules FVP yet.
export no_quantum=""

source "$ci_root/model/fvp_common.sh"
