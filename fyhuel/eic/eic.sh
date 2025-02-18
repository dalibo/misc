#!/bin/bash

dropdb bench_eic; createdb bench_eic; psql -f init.sql bench_eic

json="/tmp/eic_explain"

echo "eic, bhs_excl_time, total_exec_time, bhs_io_time"

for dataset in "cyclic" "uniform"; do
	for eic in 1 2 4 8 16 32 64; do

		rm -f $json
		psql -f eic.sql -v eic=$eic -v tname="eic_$dataset" -Aqt bench_eic

		bhs_end_time=`jq '.[0].Plan."Actual Total Time"' $json`
		bis_end_time=`jq '.[0].Plan.Plans[0]."Actual Total Time"' $json`
		total_exec_time=`jq '.[0]."Execution Time"' $json`
		bhs_io_time=`jq '.[0].Plan."Shared I/O Read Time"' $json`

		bhs_excl_time=`bc -l <<< "$bhs_end_time - $bis_end_time"`

		#echo "bhs_end_time: $bhs_end_time"
		#echo "total_exec_time: $total_exec_time"
		#echo "bis_end_time: $bis_end_time"
		#echo "bhs_excl_time: $bhs_excl_time"
		#echo "bhs_io_time: $bhs_io_time"

		echo "$dataset, $eic, $bhs_excl_time, $total_exec_time, $bhs_io_time"
	done
done
