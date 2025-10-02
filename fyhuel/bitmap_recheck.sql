-- on prend l'exemple de J6 avec seulement 1M de lignes au lieu de 10M

SET max_parallel_workers_per_gather = 0;
SET JIT = off;

DROP TABLE IF EXISTS tbt ;
CREATE UNLOGGED TABLE tbt
(i int GENERATED ALWAYS AS IDENTITY PRIMARY KEY, j int, k int, t text)
;
INSERT INTO tbt (j,k,t)
SELECT (i / 1000) , i / 777, chr (64+ (i % 58))
FROM generate_series(1,1000000) i ;
CREATE INDEX tbt_j_idx ON tbt (j) ;
CREATE INDEX tbt_k_idx ON tbt (k) ;
CREATE INDEX tbt_t_idx ON tbt (t) ;


-- On ajoute une fonction et un index fonctionel
-- La fonction hello() est d'abord créée sans le RAISE, afin de pouvoir
-- créer l'index sans se prendre des milliers de lignes de logs

CREATE OR REPLACE
FUNCTION hello(i int)
RETURNS bool
LANGUAGE plpgsql
IMMUTABLE AS $$
  BEGIN RETURN i%500=0; END
$$;

CREATE INDEX tbt_i_idx ON tbt (hello (i)) ;
VACUUM ANALYZE tbt ;

CREATE OR REPLACE
FUNCTION hello(i int)
RETURNS bool
LANGUAGE plpgsql
IMMUTABLE AS $$
  BEGIN RAISE NOTICE 'hello'; RETURN i%500=0; END
$$;

SET work_mem = '64kB';

-- on doit avoir du "lossy" et des milliers de logs "hello"
-- ainsi que la ligne suivante dans le plan:

--   Rows Removed by Index Recheck: 23920

EXPLAIN (SETTINGS, ANALYZE, BUFFERS, VERBOSE)
SELECT i, j, k, t FROM tbt WHERE j < 500 AND k < 100 AND hello(i);

RESET work_mem;

-- pas de "lossy" ni de logs "hello"
EXPLAIN (SETTINGS, ANALYZE, BUFFERS, VERBOSE)
SELECT i, j, k, t FROM tbt WHERE j < 500 AND k < 100 AND hello(i);
