\o /dev/null
SET track_io_timing = ON;
SET work_mem = '16MB';
SELECT 'foo' AS relname \gset
SET effective_io_concurrency = :eic ;
\i ~/git/public/misc/fyhuel/evict_from_both_caches.sql
\o /tmp/eic_explain
EXPLAIN (ANALYZE, SETTINGS, BUFFERS, COSTS OFF, FORMAT JSON) SELECT * FROM foo WHERE a < 100;
