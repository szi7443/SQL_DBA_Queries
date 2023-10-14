use master;
/*
TDE Encryption implementation on a sample Hospital DB database
*/


CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'DatabazeMasterDMKHeslo773';
GO

CREATE CERTIFICATE HospitalDBTDECert WITH SUBJECT = 'Hospital DB TDE Certificate'

BACKUP CERTIFICATE HospitalDBTDECert TO FILE = 'C:\SysAdm\TDE_DEMO\HospitalDBTDECert.cer'
WITH PRIVATE KEY
(
	FILE = 'C:\SysAdm\TDE_DEMO\HospitalDBTDECert.key',
	ENCRYPTION BY PASSWORD = 'PasswordPassword111Password-Do_Not_Lose_IT!'

)
/*To restore certificate on second server: */
CREATE CERTIFICATE HospitalDBTDECERT 
FROM FILE = 'C:\SysAdm\TDE_DEMO\HospitalDBTDECert.cer'
WITH PRIVATE KEY 
(
	FILE = 'C:\SysAdm\TDE_DEMO\HospitalDBTDECert.key',
	DECRYPTION BY PASSWORD = 'PasswordPassword111Password-Do_Not_Lose_IT!'
)

/* 2023-10-14 - a database level cert creation was missing */

USE HospitalDB
CREATE DATABASE ENCRYPTION KEY 
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE HospitalDBTDECert 

/*And enable TDE: */
USE [HospitalDB]
GO
ALTER DATABASE ENCRYPTION KEY ENCRYPTION BY SERVER CERTIFICATE  [HospitalDBTDECert]
GO
ALTER DATABASE [HospitalDB] SET ENCRYPTION ON
GO
/* 
in case you don't have certificate and certificate master key on the target server, you'll get
System.Data.SqlClient.SqlError: Cannot find server certificate 
with thumbprint '0x083.....'. (Microsoft.SqlServer.SmoExtended)
*/
-- check DB encryption keys:
SELECT * FROM sys.dm_database_encryption_keys;