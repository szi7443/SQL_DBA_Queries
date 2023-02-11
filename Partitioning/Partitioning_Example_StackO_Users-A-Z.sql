SELECT COUNT(*), YEAR(creationdate) FROM dbo.users GROUP BY Year(CREATIONDATE);

CREATE PARTITION FUNCTION pfYear (date) AS
RANGE LEFT FOR VALUES (
'2007-01-01',
'2008-01-01',
'2009-01-01',
'2010-01-01',
'2011-01-01',
'2012-01-01',
'2013-01-01',
'2014-01-01',
'2015-01-01',
'2016-01-01',
'2017-01-01',
'2018-01-01',
'2019-01-01',
'2020-01-01'
)
ALTER DATABASE StackOverflow ADD FILEGROUP [2007AndBelow]
ALTER DATABASE StackOverflow ADD FILEGROUP [2008]
ALTER DATABASE StackOverflow ADD FILEGROUP [2009]
ALTER DATABASE StackOverflow ADD FILEGROUP [2010]
ALTER DATABASE StackOverflow ADD FILEGROUP [2011]
ALTER DATABASE StackOverflow ADD FILEGROUP [2012]
ALTER DATABASE StackOverflow ADD FILEGROUP [2013]
ALTER DATABASE StackOverflow ADD FILEGROUP [2014]
ALTER DATABASE StackOverflow ADD FILEGROUP [2015]
ALTER DATABASE StackOverflow ADD FILEGROUP [2016]
ALTER DATABASE StackOverflow ADD FILEGROUP [2017]
ALTER DATABASE StackOverflow ADD FILEGROUP [2018]
ALTER DATABASE StackOverflow ADD FILEGROUP [2018]
ALTER DATABASE StackOverflow ADD FILEGROUP [2019]
ALTER DATABASE StackOverflow ADD FILEGROUP [2020AndAbove]


CREATE PARTITION SCHEME psYear
AS PARTITION pfYear TO
(
[2007AndBelow]
,[2008]
,[2009]
,[2010]
,[2011]
,[2012]
,[2013]
,[2014]
,[2015]
,[2016]
,[2017]
,[2018]
,[2018]
,[2019]
,[2020AndAbove]
)


USE [master]
GO
ALTER DATABASE [StackOverflow] 
ADD FILE ( NAME = N'2007AndBelow', FILENAME = N'G:\DATA\2007AndBelow.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
TO FILEGROUP [2007AndBelow]
GO

USE [master]
go

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2008', filename =
N'G:\DATA\2008.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2008]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2009', filename =
N'G:\DATA\2009.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2009]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2010', filename =
N'G:\DATA\2010.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2010]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2011', filename =
N'G:\DATA\2011.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2011]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2012', filename =
N'G:\DATA\2012.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2012]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2013', filename =
N'G:\DATA\2013.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2013]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2014', filename =
N'G:\DATA\2014.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2014]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2015', filename =
N'G:\DATA\2015.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2015]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2016', filename =
N'G:\DATA\2016.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2016]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2017', filename =
N'G:\DATA\2017.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2017]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2018', filename =
N'G:\DATA\2018.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2018]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2019', filename =
N'G:\DATA\2019.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2019]
go  

ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2020AndAbove', filename =
N'G:\DATA\2020AndAbove.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2020AndAbove]
go  



USE [StackOverflow]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UsersPToned](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AboutMe] [nvarchar](max) NULL,
	[Age] [int] NULL,
	[CreationDate] [datetime] NOT NULL,
	[CreationDate_date] [date] NOT NULL,
	[DisplayName] [nvarchar](40) NOT NULL,
	[DownVotes] [int] NOT NULL,
	[EmailHash] [nvarchar](40) NULL,
	[LastAccessDate] [datetime] NOT NULL,
	[Location] [nvarchar](100) NULL,
	[Reputation] [int] NOT NULL,
	[UpVotes] [int] NOT NULL,
	[Views] [int] NOT NULL,
	[WebsiteUrl] [nvarchar](200) NULL,
	[AccountId] [int] NULL/*,
 CONSTRAINT [PTonedPK_Users_Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
*/
/*
Just in case there is any doubt at all about this: If you specify a file group for a clustered index (primary key or unique constraint) 
in a CREATE TABLE statement, and you also specify that the table should be created on a partition scheme, SQL Server honours
the constraint - the partitioning scheme is ignored.
*/

) ON psYear(CreationDate_date)
GO

USE [StackOverflow]

GO
/**/
CREATE UNIQUE CLUSTERED INDEX [PK_CI_Date_ID] ON [dbo].[UsersPToned]
(
	[CreationDate_date] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [psYear]([CreationDate_date])

GO




USE StackOverflow;
SET IDENTITY_INSERT StackOverflow.dbo.usersptoned ON;
INSERT INTO UsersPToned
(
[Id], [AboutMe], [Age], [CreationDate], [CreationDate_date], [DisplayName], [DownVotes], [EmailHash], [LastAccessDate], [Location], [Reputation], [UpVotes], [Views], [WebsiteUrl], [AccountId]
)
SELECT 
[Id], [AboutMe], [Age], [CreationDate], CAST(creationdate AS date) AS CreationDate_date , [DisplayName], [DownVotes], [EmailHash], [LastAccessDate], [Location], [Reputation], [UpVotes], [Views], [WebsiteUrl], [AccountId]
FROM Users;
SET IDENTITY_INSERT StackOverflow.dbo.usersptoned Off;

/*
If you're like me and somehow you got file assigned to wrong filegroup, then one of the ways how to get out of this, is: 
1. empty the filegroup
2. make sure it's empty with DBCC showfilestats
3. remove the file with ALTER DATABASE [db_xy] REMOVE FILE [filename];
*/
DROP TABLE [dbo].[UsersPToned];
/*
DBCC showfilestats
*/
ALTER DATABASE stackoverflow REMOVE FILE  [2013];

/*Example #1 - splitting last partition*/
ALTER DATABASE StackOverflow ADD FILEGROUP [2021AndAbove] --adding new FG
--adding new file to the FG
ALTER DATABASE [StackOverflow] ADD FILE ( NAME = N'2021AndAbove', filename =
N'G:\DATA\2021AndAbove.ndf', size = 8192kb, filegrowth = 65536kb ) TO filegroup
[2021AndAbove]
go  
-- alter partition scheme to add new range
ALTER PARTITION SCHEME psYear NEXT USED [2021AndAbove];
-- adding new range into partition function:
ALTER PARTITION FUNCTION pfYear() SPLIT RANGE ('2021-01-01');

/* TODO - partition merge */

--tbd.


DBCC SHOWFILESTATS;


/****Partition switching example******/
/* create a table we'll switch to partition that exists in multiple filegroups. Yes this example is a bit contrived, it's for demonstration purposes */
/*Create table */
CREATE TABLE [dbo].[UsersPToned_staging](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AboutMe] [nvarchar](max) NULL,
	[Age] [int] NULL,
	[CreationDate] [datetime] NOT NULL,
	[CreationDate_date] [date] NOT NULL,
	[DisplayName] [nvarchar](40) NOT NULL,
	[DownVotes] [int] NOT NULL,
	[EmailHash] [nvarchar](40) NULL,
	[LastAccessDate] [datetime] NOT NULL,
	[Location] [nvarchar](100) NULL,
	[Reputation] [int] NOT NULL,
	[UpVotes] [int] NOT NULL,
	[Views] [int] NOT NULL,
	[WebsiteUrl] [nvarchar](200) NULL,
	[AccountId] [int] NULL/*,
 CONSTRAINT [PTonedPK_Users_Id] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
*/
/*
Just in case there is any doubt at all about this: If you specify a file group for a clustered index (primary key or unique constraint) 
in a CREATE TABLE statement, and you also specify that the table should be created on a partition scheme, SQL Server honours
the constraint - the partitioning scheme is ignored.
*/

) ON psYear(CreationDate_date);
USE [StackOverflow]

GO
/**/
CREATE UNIQUE CLUSTERED INDEX [PK_CI_Date_ID] ON [dbo].[UsersPToned_staging]
(
	[CreationDate_date] ASC,
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [psYear]([CreationDate_date])

GO

/*Before switch, let's see the stats: */
SELECT DISTINCT
    p.partition_number AS [Partition], 
    fg.name AS [Filegroup], 
    p.Rows
FROM sys.partitions p
    INNER JOIN sys.allocation_units au
    ON au.container_id = p.hobt_id
    INNER JOIN sys.filegroups fg
    ON fg.data_space_id = au.data_space_id
WHERE p.object_id = OBJECT_ID('UsersPToned_staging')
ORDER BY [Partition];


/*Now the switch*/
ALTER TABLE UsersPToned_staging
SWITCH PARTITION 12 TO UsersPToned PARTITION 12 /*Target table is partitioned as well - I need to tell the DST partition*/;
/** WATCH OUT !!! **/
/*
The destination table does need to have the same set of indexes and not only column-wise, but also other atributes like "unique"! 
*/
/* Msg 4947, Level 16, State 1, Line 285
ALTER TABLE SWITCH statement failed. There is no identical index in source table 'StackOverflow.dbo.UsersPToned' for the index 'PK_CI_Date_ID' in target table 'StackOverflow.dbo.UsersPToned_staging' .

Completion time: 2023-02-11T12:01:42.1383394-08:00
 */ 