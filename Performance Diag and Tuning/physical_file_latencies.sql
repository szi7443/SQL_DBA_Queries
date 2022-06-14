 /*
The query checks only databases containing the string 'MES' in their name, change according to your needs
*/
SELECT dbs.NAME,
       dbs.database_id,
       mfs.NAME,
       mfs.type_desc,/*vfs.*,*/
       vfs.sample_ms / 1000 / 60 / 60             AS sample_hours,
       vfs.num_of_reads,
       vfs.num_of_writes,
       vfs.num_of_bytes_read / ( 1024 * 1024 )    AS MB_read,
       vfs.num_of_bytes_written / ( 1024 * 1024 ) AS MB_written,
       io_stall_read_ms / ( 1 + num_of_reads )    AS avg_read_stall_ms,
       io_stall_write_ms / ( 1 + num_of_writes )  AS avg_write_stall_ms,
       size_on_disk_bytes / ( 1024 * 1024 )       AS MB_size_on_disk,
       Replicate('\/', 20)                        AS separator,
       vfs.*
FROM   sys.databases dbs
       CROSS apply sys.Dm_io_virtual_file_stats(dbs.database_id, NULL) vfs
       INNER JOIN sys.master_files mfs
               ON mfs.file_id = vfs.file_id
                  AND mfs.database_id = vfs.database_id
WHERE  dbs.NAME LIKE '%MES%'
ORDER  BY /*
          io_stall_read_ms / IIF(num_of_reads = 0,NULL ,num_of_reads) DESC ,*/
io_stall_write_ms / Iif(num_of_writes = 0, NULL, num_of_writes) DESC; 
=======

SELECT dbs.name, dbs.database_id, mfs.name, mfs.type_desc , /*vfs.*,*/
vfs.sample_ms / 1000 / 60 / 60 AS sample_hours, vfs.num_of_reads, vfs.num_of_writes, vfs.num_of_bytes_read / (1024*1024) AS MB_read, 
vfs.num_of_bytes_written / (1024*1024) AS MB_written,
io_stall_read_ms / (1+num_of_reads) AS avg_read_stall_ms,
io_stall_write_ms /(1+num_of_writes ) AS avg_write_stall_ms
,
size_on_disk_bytes / (1024*1024) AS MB_size_on_disk,
REPLICATE('\/',20) AS separator, vfs.*

FROM sys.databases dbs 
CROSS APPLY sys.dm_io_virtual_file_stats(dbs.database_id,NULL) vfs
INNER JOIN sys.master_files mfs ON mfs.file_id = vfs.file_id AND mfs.database_id = vfs.database_id
WHERE dbs.name LIKE '%MES%'
ORDER BY  /*
io_stall_read_ms / IIF(num_of_reads = 0,NULL ,num_of_reads) DESC ,*/
io_stall_write_ms / IIF(num_of_writes = 0,NULL ,num_of_writes)  DESC
;
