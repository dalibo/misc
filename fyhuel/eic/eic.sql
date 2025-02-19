\set ON_ERROR_STOP
\o /dev/null

SET track_io_timing = ON;
SET max_parallel_workers_per_gather = :nbw ;
SET parallel_setup_cost = 10;
SET work_mem = '16MB';
SET effective_io_concurrency = :eic ;

\set relname :tname
\i :path_to_evict_script
\o :output
EXPLAIN (ANALYZE, SETTINGS, BUFFERS, COSTS OFF, FORMAT JSON)
  SELECT * FROM :tname WHERE a < :a_max AND filler > 'fffffff';
