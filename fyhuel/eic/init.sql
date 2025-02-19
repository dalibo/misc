CREATE EXTENSION IF NOT EXISTS pg_buffercache ;

CREATE UNLOGGED TABLE eic_cyclic(a INT, filler TEXT) WITH (fillfactor = 100);
CREATE UNLOGGED TABLE eic_uniform(a INT, filler TEXT) WITH (fillfactor = 100);

INSERT INTO eic_cyclic SELECT i%2000, md5(i::text) FROM generate_series(1,2000000) AS T(i);
INSERT INTO eic_uniform SELECT 10000 * random(), md5(i::text) FROM generate_series(1,2000000) AS T(i);

VACUUM ANALYZE eic_cyclic;
VACUUM ANALYZE eic_uniform;

CREATE INDEX ON eic_cyclic(a);
CREATE INDEX ON eic_uniform(a);
