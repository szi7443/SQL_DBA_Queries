SELECT GETDATE();
GO

use ?;
declare @Indexes table
(
    Num       int identity(1,1) primary key clustered,
	SchemaName  nvarchar(255),
    TableName nvarchar(255),
    IndexName nvarchar(255)
)
INSERT INTO @Indexes
(
	SchemaName,
    TableName,
    IndexName
)
SELECT  s.name schemaName,sys.objects.name tableName,
        sys.indexes.name indexName
FROM    sys.indexes
        JOIN sys.objects ON sys.indexes.object_id = sys.objects.object_id
		JOIN sys.schemas s ON s.schema_id = sys.objects.schema_id
WHERE   sys.indexes.type_desc = 'NONCLUSTERED'
        AND sys.objects.type_desc = 'USER_TABLE'

DECLARE @Max INT
SET @Max = @@ROWCOUNT

SELECT @Max as 'max'
SELECT * FROM @Indexes

DECLARE @I INT
SET @I = 1

DECLARE @TblName NVARCHAR(255), @IdxName NVARCHAR(255) , @schemaname NVARCHAR(255)

DECLARE @SQL NVARCHAR(MAX)

WHILE @I <= @Max
BEGIN
    SELECT  @schemaname = schemaName , @TblName = TableName, @IdxName = IndexName FROM @Indexes WHERE Num = @I
    SELECT @SQL = N'ALTER INDEX ' + @IdxName + N' ON ' + @schemaname  + '.' + @TblName + '  DISABLE'; /*  use this if you want to rebuild all indexes ' REBUILD WITH (SORT_IN_TEMPDB = ON , MAXDOP = 0 , ONLINE = OFF );'*/
	PRINT @SQL;
    EXEC sp_sqlexec @SQL    

    SET @I = @I + 1
END

SELECT GETDATE();
GO