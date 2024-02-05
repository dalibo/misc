\set ON_ERROR_STOP

DROP TABLE IF EXISTS orders , products;

CREATE UNLOGGED TABLE products(
	id bigserial PRIMARY KEY,
	name TEXT,
	short_name TEXT,
	price INT
);

CREATE UNLOGGED TABLE orders(
	id bigserial,
	product_id BIGINT REFERENCES products(id),
	quantity INT
);

WITH md5s(h, r) AS (SELECT md5(i::TEXT), random() * 1000 FROM generate_series(1,100000) AS T(i))
INSERT INTO products (name, short_name, price) SELECT md5s.h, substring(md5s.h FROM 1 FOR 8), md5s.r FROM md5s;

INSERT INTO orders (product_id, quantity) SELECT i*3, random()*10 FROM generate_series(1,30000) AS T(i);

CREATE INDEX ON orders (product_id);
ALTER TABLE products ALTER COLUMN name SET STATISTICS 300;
VACUUM ANALYZE products , orders ;

EXPLAIN (ANALYZE) SELECT name, quantity FROM products p JOIN orders o ON (p.id = o.product_id)
	WHERE name LIKE 'ed%' AND short_name like 'ed%' ORDER BY quantity DESC LIMIT 10;
