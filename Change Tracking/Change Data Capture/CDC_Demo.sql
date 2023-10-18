CREATE DATABASE Test;
go
USE test

CREATE TABLE cdc_demo (
id INT PRIMARY KEY IDENTITY(1,1),
[text] nvarchar(255) default 'aaaaa'

)
EXEC sp_changedbowner 'sa'
EXEC sp_cdc_enable_db; 
/*
Columns used to uniquely identify a row for net change tracking must be included in the list of captured columns.
Add either the primary key columns of the source table, or the columns defined for the index specified in the parameter @index_name to 
the list of captured columns and retry the operation.

*/
EXEC sp_cdc_enable_table @source_schema = 'dbo' , @source_name = 'cdc_demo', @captured_column_list = 'id,text' , @role_name = 'CDC'

/* show me current config */
EXEC sys.sp_cdc_help_change_data_capture

DECLARE @from_lsn binary(10), @to_lsn binary(10)
SET @from_lsn = sys.fn_cdc_get_min_lsn('SalesLT.address')
SET @to_lsn = sys.fn_cdc_get_max_lsn()
SELECT * FROM cdc.fn_get_all_changes_SalesLT_address(@from_lsn, @to_lsn, N'all');

EXEC sp.cdc_disable_table  @source_schema = 'dbo' , @source_name = 'cdc_demo', @capture_instance = 'all' -- stop all CDC instances on the table
-- disable for the whole database: 
EXEC sp_cdc_disable_db;