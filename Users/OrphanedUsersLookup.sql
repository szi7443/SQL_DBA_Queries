DECLARE @database NVARCHAR(255);
DECLARE @sql NVARCHAR(MAX);

-- Cursor to select all user databases
DECLARE db_cursor CURSOR FOR
SELECT name 
FROM sys.databases 
WHERE database_id > 4;  -- Exclude system databases

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @database;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'USE [' + @database + ']; ' +
                'SELECT ''' + @database + ''' AS database_name, dp.name, dp.type, dp.sid ' +
                'FROM sys.database_principals dp ' +
                'LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid ' +
                'WHERE sp.sid IS NULL AND dp.type IN (''U'', ''S'', ''C'', ''K'') AND dp.principal_id > 4;';

    EXEC sp_executesql @sql;  -- Execute the dynamic SQL

    FETCH NEXT FROM db_cursor INTO @database;
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;
