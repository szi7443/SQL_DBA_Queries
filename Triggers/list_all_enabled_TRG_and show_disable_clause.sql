USE YOURDBNAMEGOESHERE;

seLECT 
	t2.[name] TableTriggerReference
	, SCHEMA_NAME(t2.[schema_id]) TableSchemaName
	, t3.[rowcnt] TableReferenceRowCount
	, t1.[name] TriggerName
	, 'ALTER TABLE ' + SCHEMA_NAME(t2.schema_id) + '.' + t2.[name] + ' DISABLE TRIGGER ' + t1.[name] Script
FROM sys.triggers t1
	INNER JOIN sys.tables t2 ON t2.object_id = t1.parent_id
	INNER JOIN sys.sysindexes t3 On t2.object_id = t3.id
WHERE t1.is_disabled = 0
	AND  t1.is_ms_shipped = 0
	AND t1.parent_class = 1
	
	
	
	
	
	
	
	
	
	
	
	