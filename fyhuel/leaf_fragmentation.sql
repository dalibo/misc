\set ECHO queries
CREATE EXTENSION IF NOT EXISTS pgstattuple;

DROP TABLE IF EXISTS foo CASCADE;

CREATE UNLOGGED TABLE foo(a INT);
ALTER TABLE foo SET (autovacuum_enabled = false);

CREATE INDEX ON foo(a);

INSERT INTO foo(a) SELECT i FROM generate_series(1000000, 0, -1) AS T(i);
VACUUM ANALYZE foo;

SELECT * FROM pgstatindex('foo_a_idx');

SELECT avg_leaf_density::int AS density FROM pgstatindex('foo_a_idx') \gset

-- Cet index aura une fragmentation nulle et la même densité que l'autre
CREATE INDEX foo_a_idx_ff ON foo(a) WITH (fillfactor = :density);

SELECT * FROM pgstatindex('foo_a_idx_ff');

\echo "Redémarrez postgres, videz le cache système, et jouez les autres commandes du script"
\quit

UPDATE pg_index SET indisvalid = false WHERE indexrelid = 'foo_a_idx_ff'::regclass;

EXPLAIN (ANALYZE, BUFFERS, COSTS off) SELECT * FROM FOO ORDER BY a;

-- Execution Time ~= 400 ms chez moi

UPDATE pg_index SET indisvalid = false WHERE indexrelid = 'foo_a_idx'::regclass;
UPDATE pg_index SET indisvalid = true WHERE indexrelid = 'foo_a_idx_ff'::regclass;

-- Redémarrez postgres et videz le cache système
EXPLAIN (ANALYZE, BUFFERS, COSTS off) SELECT * FROM foo ORDER BY a;

-- Execution Time ~= 140 ms chez moi
