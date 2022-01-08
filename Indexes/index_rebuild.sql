/* index rebuild script - including columnstore(rebuilding columnstore might harm, tho!)*/
USE <enter db name here>
EXECUTE sp_MSforeachtable ' Print ''?''; SET QUOTED_IDENTIFIER ON;
IF EXISTS (SELECT * FROM sys.INDEXES WHERE object_id = object_id(''?'') AND type = 6)
ALTER INDEX ALL ON ? REBUILD ELSE
ALTER INDEX ALL ON ? REBUILD WITH (FILLFACTOR = 100)'