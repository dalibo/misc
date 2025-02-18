\o /dev/null
SET track_io_timing = ON;
SET max_parallel_workers_per_gather = 0;
SET work_mem = '16MB';
SELECT :'tname' AS relname \gset
SET effective_io_concurrency = :eic ;
\i ~/git/public/misc/fyhuel/evict_from_both_caches.sql
\o /tmp/eic_explain
EXPLAIN (ANALYZE, SETTINGS, BUFFERS, COSTS OFF, FORMAT JSON) SELECT * FROM :tname WHERE a < 100;
