#!/bin/bash

set -e

debug="$1"

dname=`dirname "${BASH_SOURCE[0]}"`

source "$dname/eic_config"

function check_node_type()
{
	node_type=$1
	expected=$2

	if [[ "$node_type" != "$expected" ]]; then
		echo "The root node type should be a $expected,"\
			"but it is $node_type"
		exit 1
	fi
}

dropdb --if-exists bench_eic; createdb bench_eic; psql -Aqt -f "$dname/init.sql" bench_eic

json="/tmp/eic_explain"
subjson="/tmp/eic_explain_sub"

echo "dataset, nbw, eic, bhs_excl_time, total_exec_time, bhs_io_time"

for dataset in "cyclic" "uniform"; do

	if [[ "$dataset" == "uniform" ]]; then
		a_max=140
	else
		a_max=100
	fi

	for nbw in 0 2; do
		for eic in 1 2 4 8 16 32 64; do

			rm -f $json
			psql -f "$dname/eic.sql" \
				-v output=$json \
				-v nbw=$nbw \
				-v eic=$eic \
				-v a_max=$a_max \
				-v tname="eic_$dataset" \
				-v path_to_evict_script="$PATH_TO_EVICT_SCRIPT" \
				-Aqt bench_eic

			total_exec_time=`jq '.[0]."Execution Time"' $json`

			if [ $nbw -gt 0 ]; then
				root_node_type=`jq -r '.[0].Plan."Node Type"' $json`
				check_node_type "$root_node_type" 'Gather'
				topm1_node_type=`jq -r '.[0].Plan.Plans[0]."Node Type"' $json`
				check_node_type "$topm1_node_type" 'Bitmap Heap Scan'
				jq -r '.[0].Plan.Plans[0]' $json > $subjson
			else
				root_node_type=`jq -r '.[0].Plan."Node Type"' $json`
				check_node_type "$root_node_type" 'Bitmap Heap Scan'
				jq -r '.[0].Plan' $json > $subjson
			fi

			bhs_end_time=`jq '."Actual Total Time"' $subjson`
			bis_end_time=`jq '.Plans[0]."Actual Total Time"' $subjson`
			bhs_io_time=`jq '."Shared I/O Read Time"' $subjson`

			if [[ $debug == "true" ]]; then
				echo "bhs_end_time: $bhs_end_time"
				echo "bis_end_time: $bis_end_time"
				echo "bhs_io_time: $bhs_io_time"
			fi

			bhs_excl_time=`bc -l <<< "$bhs_end_time - $bis_end_time"`

			echo "$dataset, $nbw, $eic, $bhs_excl_time, $total_exec_time, $bhs_io_time"
		done
	done
done
