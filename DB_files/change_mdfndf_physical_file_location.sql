/*
Example of move and rename file within the filesystem
*/
ALTER DATABASE StandaTest SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE StandaTest SET OFFLINE;
/*We point the logical name to physical file in different location - need to manually move and rename the file in the filesystem
is still required
*/
ALTER DATABASE StandaTest MODIFY FILE (Name='StandaTest', FILENAME='D:\DATA\MSSQL15.MSSQLSERVER\StandaTest_renamed.mdf')
GO

ALTER DATABASE StandaTest SET ONLINE
Go
ALTER DATABASE StandaTest SET MULTI_USER
Go

