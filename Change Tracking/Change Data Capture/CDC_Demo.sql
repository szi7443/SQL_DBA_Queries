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