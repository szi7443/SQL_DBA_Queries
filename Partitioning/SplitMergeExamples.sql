USE PartitioningTest;
DROP TABLE Orders;
CREATE TABLE Orders
(
ID int IDENTITY(1,1),
CustomerID INT, 
DateIssued datetime, 
Comment VARCHAR(160)
, 
CONSTRAINT PK_ORDERS PRIMARY KEY CLUSTERED 
([DateIssued] ASC , [ID] ASC)
) 
ON psOrders(DateIssued)



WITH Tally (N) AS
(
    SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_columns a CROSS JOIN sys.all_columns b
)

INSERT INTO Orders_Staging(CustomerID, DateIssued, Comment)
SELECT TOP 3000  ROUND(RAND()*100,0,0), DATEADD(HOUR,n,'2025-05-06 14:00:00.000'), 'dadadaad'
FROM Tally;
GO 50

SELECT MAX(dateissued) FROM Orders_Staging;


CREATE TABLE Orders_Existing
(
ID int IDENTITY(1,1),
CustomerID INT, 
DateIssued datetime, 
Comment VARCHAR(160)
,
CONSTRAINT PK_OrdersEx PRIMARY KEY CLUSTERED
([ID] ASC)
) 
ON [PRIMARY]
/* Partition SPLIT -> musím øíct partition scheme, jaká další filegroup bude po pøidání nové partition použita */
ALTER PARTITION sCHEME psOrders NEXT USED [PRIMARY]
ALTER PARTITION FUNCTION pfOrders() SPLIT RANGE ('2022-01-01 14:00')
ALTER PARTITION sCHEME psOrders NEXT USED [PRIMARY]
ALTER PARTITION FUNCTION pfOrders() SPLIT RANGE ('2023-01-01 14:00')
/*
   MERGE */

ALTER PARTITION FUNCTION pfOrders() MERGE RANGE ('2020-01-01')



CREATE TABLE Orders_Staging 
(
ID int IDENTITY(1,1),
CustomerID INT, 
DateIssued datetime, 
Comment VARCHAR(160)
,
CONSTRAINT PK_OrdersEx PRIMARY KEY CLUSTERED
([ID] ASC)
) 
ON [PRIMARY]