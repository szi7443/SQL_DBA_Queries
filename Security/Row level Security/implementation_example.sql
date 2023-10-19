/*
Row level security implementation example
- Users need to be created 
- inline TVF needs to be created
- Security Policy needs to be created
- both sec. policy and inline TVF are created PER TABLE !!! 

*/
USE DB
CREATE USER FRED WITHOUT LOGIN;
CREATE USER Steve WITHOUT LOGIN;
CREATE USER CEO WITHOUT LOGIN;

CREATE FUNCTION dbo.fn_SalesSecurity(@UserName AS sysname)
	RETURNS TABLE
WITH SCHEMABINDING
AS 
RETURN SELECT 1 AS fn_SalesSecurity_Result
	WHERE @UserName = USER_NAME()
	OR USER_NAME = 'CEO'
GO 

CREATE SECURITY POLICY UserFilter
ADD FILTER PREDICATE dbo.fn_SalesSecurity(UserName)
ON dbo.Sales
WITH (STATE= ON);
GO