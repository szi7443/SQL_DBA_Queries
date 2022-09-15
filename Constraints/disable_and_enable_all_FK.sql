/*
*Disabling all foreign keys in database on all tables: 
*
*/

EXEC sp_msforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

/*
*Enabling all foreign keys in database on all tables: 
*
*/
EXEC sp_msforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
