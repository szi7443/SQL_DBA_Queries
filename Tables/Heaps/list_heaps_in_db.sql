
SELECT t.name AS table_name, s.name + '.' + t.name AS table_schema 
FROM sys.tables t
INNER JOIN sys.indexes i ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE i.type = 0
;