USE master
GO
ALTER DATABASE adventureworks2019
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON)



USE [AdventureWorks2019]
GO
ALTER TABLE [Person].[Person] ENABLE CHANGE_TRACKING WITH(TRACK_COLUMNS_UPDATED = ON)
GO

GO


SELECT TOP(30) * FROM person.person;

BEGIN TRAN;
 UPDATE person.Person SET LastName = N'Dickinson' WHERE BusinessEntityID = 5 ; 
 COMMIT;

 BEGIN TRAN;
 UPDATE person.Person SET LastName = N'Stevenson' WHERE BusinessEntityID = 5 ; 
 COMMIT;

  BEGIN TRAN;
 UPDATE person.Person SET LastName = N'Olafsson' WHERE BusinessEntityID = 5 ; 
 COMMIT;

DECLARE @last_ver INT;
SELECT @last_ver = 
CHANGE_TRACKING_CURRENT_VERSION ( )  ;
SELECT @last_ver;
 

 /*Syntax SQL*/
 /*
 CHANGETABLE (  
    { CHANGES <table_name> , <last_sync_version> 
    | VERSION <table_name> , <primary_key_values> } 
    , [ FORCESEEK ] 
    )  
[AS] <table_alias> [ ( <column_alias> [ ,...n ] )  
  
<primary_key_values> ::=  
( <column_name> [ , ...n ] ) , ( <value> [ , ...n ] )
 */
 SELECT * FROM changetable (CHANGES [person].[person],3) AS CT
 INNER JOIN person.person p ON p.BusinessEntityID = CT.BusinessEntityID
 ORDER BY CT.SYS_CHANGE_VERSION


 USE AdventureWorks2019;
 ALTER TABLE person.person
 DISABLE change_tracking ;

 USE master;
 ALTER DATABASE AdventureWOrks2019
 SET CHANGE_TRACKING = OFF;