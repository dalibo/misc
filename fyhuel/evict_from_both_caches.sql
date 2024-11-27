SELECT DISTINCT pg_buffercache_evict(bufferid)
  FROM pg_buffercache
 WHERE relfilenode = pg_relation_filenode(:'relname');

SELECT current_setting('data_directory') || '/' || pg_relation_filepath(:'relname') AS relpath \gset

COPY (SELECT format ('fincore %s; dd oflag=nocache conv=notrunc,fdatasync count=0 of=%s',
		     :'relpath', :'relpath')
     ) TO '/tmp/evict_index_from_page_cache.sh';

\! chmod +x /tmp/evict_index_from_page_cache.sh

\! /tmp/evict_index_from_page_cache.sh

