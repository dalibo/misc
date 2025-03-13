SELECT DISTINCT pg_buffercache_evict(bufferid)
  FROM pg_buffercache
 WHERE relfilenode = pg_relation_filenode(:'relname');

SELECT pgfadvise_dontneed(:'relname');
