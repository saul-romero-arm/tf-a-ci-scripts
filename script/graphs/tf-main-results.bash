#!/usr/bin/env bash
#
# Copyright (c) 2022 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

set -euo pipefail

# Build and Jenkins URL.
sub_build_url=${1}
job_name="${2:-"tf-a-ci-gateway"}"
filter=${3:-".*"}

jenkins="${sub_build_url%%/job*}"

# Utilise default paths to output files if none provided.
job_target="$(dirname ${sub_build_url#*/job/})"
PNGFILE=${PNGFILE:=${job_target}-result.png}
CSVFILE=${CSVFILE:=${job_target}-result.csv}

# Remove csv output file if it exists to append to empty file
: > "${CSVFILE}"

readarray -t sub_builds < <(curl -sSL "${sub_build_url}/api/json" | jq -Rr '
	fromjson? | [
		.subBuilds[]? | select(.jobName == "'${job_name}'") | .url
	] | .[]')

# Get a csv list of relative paths to report.json, or "-" if no report.json
report_rel_paths_url="${jenkins}/{$(echo $(IFS=,; echo "${sub_builds[*]}"))}/api/json"

readarray -t report_paths < <(curl -fsSL --fail-early "${report_rel_paths_url}" \
					| sed 's/--_curl_--.*$//' \
					| sed -e 's/^{/'$(printf "\x1e")'{/' \
					| jq -sr --seq '
				 	[ .[]
						| [ .artifacts[]?
						| select (.fileName == "report.json")
						| .relativePath ]
						| if length > 0 then .[] else "-" end ]
					| .[]')

# Combine sub build urls with relative path to "report.json"
# the empty entries are intentionally kept as -, so the output array can
# be mapped onto ${sub_build_list}
report_urls="$jenkins/{"
for i in "${!sub_builds[@]}"
do
	if [[ ${report_paths[i]} != "-" ]]
	then
		report_urls="${report_urls}${sub_builds[i]}/artifact/${report_paths[i]},"
	fi
done

# Strip last comma and add closing brace
report_urls="${report_urls%?}}"

# Get Child build information from each report.json.
readarray -t child_file_list_array < <(curl -sL "${report_urls}" -o -\
                        | sed 's/--_curl_--.*$//' \
                        | jq -sr --arg FILTER "${filter}" \
                            '[.[]
                             | .job as $job
                             | [ .child_build_numbers?, [(.test_files[]
                               | sub("\\.test";"")
                               | split("%") as $config
                               | { group: $config[1], suite: $config[2]})]]
                             | transpose
                             | map( {($job + "/" + .[0]) : .[1]} | to_entries )
                             | add
                             | map(select(.value.suite | test(".*"; "il")?
							               and (endswith("nil")
										     or endswith("norun-fip.dummy") | not)))
                             | if ( length > 0 )
                                then .[] else empty end
                             | .value.group, (.value.suite | gsub("\\,nil";"")), .key]
							 | .[]')

# These three arrays should be the same length, and values at the same index
# correspond to the same child build
declare -a tftf_keys tftf_suite tftf_group

for i in $(seq 0 3 $((${#child_file_list_array[@]}-1))) ; do
	tftf_group+=("${child_file_list_array[$i]}")
	tftf_suite+=("${child_file_list_array[$i+1]}")
	tftf_keys+=("${child_file_list_array[$i+2]}")
done


child_output_results_url="${jenkins}/job/{$(echo $(IFS=,; echo "${tftf_keys[*]}"))}/api/json"

# Retrieve relative path to either "uart0_full.txt" (FVP) or
# "job_output.log" (LAVA) for each child job. Once again values where no match
# is found are intentionally kept as "-" so the array can be correlated with
# ${tftf_suite}.
readarray -t child_output_results < <(curl -fsSL --fail-early "$child_output_results_url" \
                 | sed 's/}{/}\n{/g' \
                 | jq -sr '[ .[]
                             | ([ .artifacts[]?
                                  | select(.fileName == "uart0_full.txt"
                                  or .fileName == "job_output.log"
                                  or .fileName == "lava-uart0.log") ]
                             |  if length > 0
                                then .[0].relativePath else "-" end), .result ]
                           | .[]')

# Combine job and child_build number with relative path to output file
testlog_urls="${jenkins}/job/{"
tftf_child_results=()

for i in $(seq 0 2 $((${#child_output_results[@]}-1))) ; do
	testlog_urls+="${tftf_keys[$((i/2))]}/artifact/${child_output_results[$i]},"
	tftf_child_results+=(${child_output_results[$((i+1))]})
done

# Remove final comma and append a closing brace
testlog_urls="${testlog_urls%?}}"

# Retrieve the log for each child with --include to also retrieve the HTTP
# header and grep for a block like:
# Tests Skipped : 125
# Tests Passed  : 45
# Tests Failed  : 0
# Tests Crashed : 0
#
# If none is found the line HTTP is used to delemit each entry
#
# Logs from Lava each message is wrapped with braces and has some pre-amble,
# which is removed with sed.

tftf_result_keys=(
        "TestGroup" "TestSuite" "URL" "Result" "Passed" "Failed" "Crashed" "Skipped"
)
declare -A results_split="( $(for ord_ in ${tftf_result_keys[@]} ; do echo -n "[$ord_]=\"\" "; done))"
declare output_csv_str="" csv_row=""

read -ra tftf_urls <<< "$(eval "echo ${testlog_urls}")"

# FIXME adjust this so we can handle both LAVA logs
# for each test suite
# curl the result log if its not '-'
# remove debug information
# if results is none:
	# use "Result"
# else
	# read each key
# write row to csv

# Sort results into rows:
for i in ${!tftf_suite[*]}; do
	results_split["TestGroup"]="${tftf_group[$i]:-}"
	results_split["TestSuite"]="\"${tftf_suite[$i]:-}\""
	results_split["URL"]="${tftf_urls[$i]:-}"
	results_split["Result"]="${tftf_child_results[$i]:-}"

	# Skipped/Crashed are always zero if no test block is found
	results_split["Skipped"]="0"
	results_split["Crashed"]="0"
	if [[ "${results_split["Result"]}" == "SUCCESS" ]];
	then
		results_split["Passed"]="1"
		results_split["Failed"]="0"
	else
		results_split["Passed"]="0"
		results_split["Failed"]="1"
	fi

	readarray -t raw_result < <(curl -sL --include "${results_split["URL"]}" \
			| sed 's/.*msg": "//g' \
			| grep --text -E "^Tests|HTTP\/")

	for line in "${raw_result[@]}"; do
		if [[ "${line}" == Test* ]]
		then
			k=$(echo "${line}" | awk -F ' ' '{print $2}')
			count="${line//[!0-9]/}"
			results_split[$k]=$count
		fi
	done

	# Generate CSV row using array of ordinals to align with headers.
	readarray -t row < <(for k in ${tftf_result_keys[@]} ; do echo "${results_split[$k]}"; done )
	output_csv_str="${output_csv_str} $(echo $(IFS=,; echo "${row[*]}"))"
	unset results_split[{..}] row
done

# Replace spaces in header with commas and print to the output file.
echo $(IFS=,; echo "${tftf_result_keys[*]}") > ${CSVFILE}

# Sort Filenames alphabetically and store in csv for gnuplot
sorted=($(IFS=$' '; sort <<<$output_csv_str))
printf "%b\n" "${sorted[@]}" >> ${CSVFILE}

# Produce PNG image of graph using gnuplot and .plot description file
gnuplot -e "jenkins_id='$sub_build_url'" -c ${0%bash}plot \
        "$CSVFILE" > "$PNGFILE"
