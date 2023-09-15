SELECT page_count
,avg_record_size_in_bytes
,avg_page_space_used_in_percent
,forwarded_record_count
FROM sys.dm_db_index_physical_stats(db_id('DML_DB'), object_id(N'dbo.Forwarding_Pointer'), 0, NULL, 'DETAILED');
GO
/*


*/
/*Forwarded fetch count:
(how many times was the heap touched and had its forward pointers used)
 */
;with heaps as ( 
select 
    DB_NAME(DB_ID()) dbname, object_name ( p.object_id ) objname, sum(row_count) row_count,
    DB_ID() database_id, p.object_id objectid
from 
    sys.dm_db_partition_stats p
    join sys.objects o on o.object_id = p.object_id 
WHERE 
    index_id = 0 and o.is_ms_shipped = 0 --and row_count > 0
    group by p.object_id ) 
select 
    h.*, 
    forwarded_fetch_count
from heaps h
    cross apply sys.dm_db_index_operational_stats(database_id, objectid, 0, null) ps
    WHERE forwarded_fetch_count > 0 ORDER BY forwarded_fetch_count DESC
/*
Forwared record count - how many forward pointers does the heap have regardless of their usage count
*/
SELECT page_count, OBJECT_NAME(ps.object_id)
,avg_record_size_in_bytes
,avg_page_space_used_in_percent
,forwarded_record_count 
FROM sys.dm_db_index_physical_stats(db_id('your_db_name'), NULL,NULL, NULL, 'DETAILED') AS ps
WHERE forwarded_record_count IS NOT NULL AND forwarded_record_count > 0
GO