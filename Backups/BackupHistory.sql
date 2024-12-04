/* query that interviews msdb for backup history */
SELECT 
    bs.database_name AS 'Database Name',
    bs.backup_start_date AS 'Backup Start',
    bs.backup_finish_date AS 'Backup Finished',
    DATEDIFF(MINUTE, bs.backup_start_date, bs.backup_finish_date) AS 'Duration (min)',
    bmf.physical_device_name AS 'Backup File',
    CASE
        WHEN bs.[type] = 'D' THEN 'Full Backup'
        WHEN bs.[type] = 'I' THEN 'Differential Database'
        WHEN bs.[type] = 'L' THEN 'Log'
        WHEN bs.[type] = 'F' THEN 'File/Filegroup'
        WHEN bs.[type] = 'G' THEN 'Differential File'
        WHEN bs.[type] = 'P' THEN 'Partial'
        WHEN bs.[type] = 'Q' THEN 'Differential partial'
    END AS 'Backup Type',
    ROUND(((bs.backup_size / 1024) / 1024), 2) AS 'Backup Size (MB)',
    ROUND(((bs.compressed_backup_size / 1024) / 1024), 2) AS 'Compressed Backup Size (MB)'
FROM 
    msdb..backupmediafamily bmf
INNER JOIN 
    msdb..backupset bs ON bmf.media_set_id = bs.media_set_id
ORDER BY 
    bs.backup_start_date DESC;
