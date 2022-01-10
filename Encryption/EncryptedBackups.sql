/*
encrypted backups lab
*/
use master;
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'HesloChraniciTajemstviVMasterDatabaziStando7443.'
CREATE CERTIFICATE HospitalDBBackupCert WITH SUBJECT = 'HospitalDB Backup certificate';

BACKUP CERTIFICATE HospitalDBBackupCert TO File = 'F:\BACKUP\certs\backup\HospitalDBBackupCert.cer'
WITH PRIVATE KEY 
(
	FILE = 'F:\data\HospitalDBBackupCert.key',
	ENCRYPTION BY PASSWORD = 'JestliT0ZtratisNerozsifrujesJ3dinouZ4lohuNaJinemServeru' /* heslo k zasifrovani privatniho klice cert. */
)

/*
Pro obnovu na jinem serveru: 
*/
-- vytvorit master key na master DB ciloveho serveru
/*
F:\BACKUP\certs
*/

CREATE CERTIFICATE HospitalDBBackupCert FROM FILE =  'F:\BACKUP\certs\HospitalDBBackupCert.cer'
WITH PRIVATE KEY (
	FILE =  'F:\BACKUP\certs\HospitalDBBackupCert.key',
	DECRYPTION BY PASSWORD = 'JestliT0ZtratisNerozsifrujesJ3dinouZ4lohuNaJinemServeru'
)
