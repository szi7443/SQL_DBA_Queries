:setvar path "X:\DB_NAME_HERE\bcpexport\"
:setvar username adminusernamesourcehere
:setvar password ***********************
:setvar target_server .
:setvar target_username admintargetnamehere
:setvar target_password ***********************
use DB_NAME_HERE;
select export = concat('bcp ', DB_NAME(), '.',     
    SCHEMA_NAME(schema_id), '.', name,
    ' out $(path)', SCHEMA_NAME(schema_id), '_', name, '.bcp ',
    ' -S"', @@servername,'"',
    ' -n -U"$(username)" -P"$(password)"')
from sys.tables
where type = 'U'
and is_ms_shipped = 0
and temporal_type in (0,2);select import = concat('bcp ', DB_NAME(), '.',
    SCHEMA_NAME(schema_id), '.', name,
    ' in $(path)', SCHEMA_NAME(schema_id), '_', name, '.bcp ',
    ' -S"$(target_server)','"',
    ' -n -U"$(target_username)" -P"$(target_password)"')
from sys.tables
where type = 'U'
and is_ms_shipped = 0
and temporal_type in (0,2);