\set ON_ERROR_STOP
SET random_page_cost = 1.2;

SELECT 400000 AS nbp \gset

DROP TABLE IF EXISTS orders , products;

CREATE TABLE products(
	id bigserial PRIMARY KEY,
	name TEXT,
	price INT
);

CREATE TABLE orders(
	id bigserial,
	product_id BIGINT, -- REFERENCES products(id),
	quantity INT
);

-- utile si on veut forcer le trait, mais pas nécessaire
--ALTER TABLE orders ALTER COLUMN id SET STATISTICS 10;
--ALTER TABLE orders ALTER COLUMN product_id SET STATISTICS 10;
--ALTER TABLE orders ALTER COLUMN quantity SET STATISTICS 10;

INSERT INTO products (name, price) SELECT md5(i::TEXT), random() * 1000 FROM generate_series(1, :nbp) AS T(i);

INSERT INTO orders (product_id, quantity) SELECT (i%1000) + 1, random()*10 FROM generate_series(1, 3000000) AS T(i);
INSERT INTO orders (product_id, quantity) SELECT (i%:nbp) + 1, random()*10 FROM generate_series(1, 3000000) AS T(i);

CREATE INDEX ON orders (product_id);
ALTER TABLE products ALTER COLUMN price SET STATISTICS 2000;
VACUUM ANALYZE products , orders ;

ALTER TABLE orders ADD FOREIGN KEY (product_id) REFERENCES products(id);

CREATE INDEX ON products (price);

SELECT 'SELECT name, sum(quantity) FROM products p JOIN orders o ON (p.id = o.product_id)
	WHERE price = 769
	GROUP BY name ORDER BY 2 DESC LIMIT 10;' AS query \gset

EXPLAIN (ANALYZE, BUFFERS, SETTINGS) :query

SELECT * FROM pg_stats WHERE tablename = 'orders' AND attname = 'product_id';


CREATE OR REPLACE FUNCTION get_sub_plan(query text) RETURNS jsonb
   LANGUAGE plpgsql AS
$$DECLARE
   plan jsonb;
BEGIN
   EXECUTE 'EXPLAIN (FORMAT JSON) ' || query INTO plan;
 
   RETURN (plan->0->'Plan'->'Plans'->0->'Plans'->0->'Plans'->0->'Plans'->0->'Plans'->0->'Plans'->0->'Plans');
END;$$;

SELECT get_sub_plan(:'query')->1->>'Total Cost' AS index_scan_cost \gset
SELECT get_sub_plan(:'query')->1->>'Plan Rows' AS n_inner \gset
SELECT get_sub_plan(:'query')->0->>'Plan Rows' AS n_outer \gset

SELECT (current_setting('seq_page_cost')::numeric * pg_relation_size('products') / 8192 +
                (
                        + current_setting('cpu_tuple_cost')::numeric * :nbp
                        + current_setting('cpu_operator_cost')::numeric * :nbp
                ) / 2.4
        ) AS parallel_seq_scan_cost \gset

\echo index_scan_cost is :index_scan_cost
\echo parallel_seq_scan_cost is :parallel_seq_scan_cost
\echo n_outer is :n_outer
\echo n_inner is :n_inner

SELECT :index_scan_cost * :n_outer + :parallel_seq_scan_cost + current_setting('cpu_tuple_cost')::numeric * (:n_inner * :n_outer) AS nested_loop_cost;

ALTER TABLE orders ALTER COLUMN product_id SET (n_distinct = :nbp);
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS, SETTINGS) :query
