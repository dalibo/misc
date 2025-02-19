#!/bin/bash

set -e

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

dropdb bench_eic; createdb bench_eic; psql -f init.sql bench_eic

json="/tmp/eic_explain"

echo "dataset, nbw, eic, bhs_excl_time, total_exec_time, bhs_io_time"

for dataset in "cyclic" "uniform"; do
	for nbw in 0 2; do
		for eic in 1 2 4 8 16 32 64; do

			rm -f $json
			psql -f eic.sql -v nbw=$nbw -v eic=$eic -v tname="eic_$dataset" -Aqt bench_eic

			total_exec_time=`jq -r '.[0]."Execution Time"' $json`

			if [ $nbw -gt 0 ]; then
				root_node_type=`jq -r '.[0].Plan."Node Type"' $json`
				check_node_type "$root_node_type" 'Gather'
				topm1_node_type=`jq -r '.[0].Plan.Plans[0]."Node Type"' $json`
				check_node_type "$topm1_node_type" 'Bitmap Heap Scan'
				bhs_end_time=`jq -r '.[0].Plan.Plans[0]."Actual Total Time"' $json`
				bis_end_time=`jq -r '.[0].Plan.Plans[0].Plans[0]."Actual Total Time"' $json`
				bhs_io_time=`jq -r '.[0].Plan.Plans[0]."Shared I/O Read Time"' $json`
			else
				root_node_type=`jq -r '.[0].Plan."Node Type"' $json`
				check_node_type "$root_node_type" 'Bitmap Heap Scan'
				bhs_end_time=`jq -r '.[0].Plan."Actual Total Time"' $json`
				bis_end_time=`jq -r '.[0].Plan.Plans[0]."Actual Total Time"' $json`
				bhs_io_time=`jq -r '.[0].Plan."Shared I/O Read Time"' $json`
			fi

			bhs_excl_time=`bc -l <<< "$bhs_end_time - $bis_end_time"`

			#echo "bhs_end_time: $bhs_end_time"
			#echo "total_exec_time: $total_exec_time"
			#echo "bis_end_time: $bis_end_time"
			#echo "bhs_excl_time: $bhs_excl_time"
			#echo "bhs_io_time: $bhs_io_time"

			echo "$dataset, $nbw, $eic, $bhs_excl_time, $total_exec_time, $bhs_io_time"
		done
	done
done
