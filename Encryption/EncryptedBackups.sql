 /*
encrypted backups lab
*/
USE master;

CREATE master KEY encryption BY password =
'HesloChraniciTajemstviVMasterDatabaziStando7443.'

CREATE certificate hospitaldbbackupcert WITH subject =
'HospitalDB Backup certificate';

BACKUP certificate hospitaldbbackupcert TO FILE =
'F:\BACKUP\certs\backup\HospitalDBBackupCert.cer' WITH private KEY ( FILE =
'F:\data\HospitalDBBackupCert.key', encryption BY password =
'JestliT0ZtratisNerozsifrujesJ3dinouZ4lohuNaJinemServeru'
/* heslo k zasifrovani privatniho klice cert. */
)

/*
Pro obnovu na jinem serveru: 
*/
-- vytvorit master key na master DB ciloveho serveru
/*
F:\BACKUP\certs
*/
CREATE certificate hospitaldbbackupcert FROM FILE =
'F:\BACKUP\certs\HospitalDBBackupCert.cer' WITH private KEY ( FILE =
'F:\BACKUP\certs\HospitalDBBackupCert.key', decryption BY password =
'JestliT0ZtratisNerozsifrujesJ3dinouZ4lohuNaJinemServeru' )  