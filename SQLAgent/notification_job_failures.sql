USE [dbadmintools]
GO

/****** Object:  StoredProcedure [dbo].[monitor_job_failures]    Script Date: 23.03.2023 13:15:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[monitor_job_failures]
	@minutes_to_monitor SMALLINT = 1440
AS
BEGIN
	SET NOCOUNT ON;
	-- Determine UTC offset so that all times can easily be converted to UTC.
	DECLARE @utc_offset INT;
	SELECT
		@utc_offset = -1 * DATEDIFF(HOUR, GETUTCDATE(), GETDATE());
MERGE INTO dbo.sql_server_agent_job AS TARGET
		USING (SELECT
					sysjobs.job_id AS sql_server_agent_job_id_guid,
					sysjobs.name AS sql_server_agent_job_name,
					sysjobs.date_created AS job_create_datetime_utc,
					sysjobs.date_modified AS job_last_modified_datetime_utc,
					sysjobs.enabled AS is_enabled,
					0 AS is_deleted,
					ISNULL(syscategories.name, '') AS job_category_name
			   FROM msdb.dbo.sysjobs
			   LEFT JOIN msdb.dbo.syscategories
			   ON syscategories.category_id = sysjobs.category_id) AS SOURCE
		ON (SOURCE.sql_server_agent_job_id_guid = TARGET.sql_server_agent_job_id_guid)
		WHEN NOT MATCHED BY TARGET
			THEN INSERT
				(sql_server_agent_job_id_guid, sql_server_agent_job_name, job_create_datetime_utc, job_last_modified_datetime_utc,
				 is_enabled, is_deleted, job_category_name)
			VALUES	(
				SOURCE.sql_server_agent_job_id_guid,
				SOURCE.sql_server_agent_job_name,
				SOURCE.job_create_datetime_utc,
				SOURCE.job_last_modified_datetime_utc,
				SOURCE.is_enabled,
				SOURCE.is_deleted,
				SOURCE.job_category_name)
		WHEN MATCHED AND SOURCE.job_last_modified_datetime_utc > TARGET.job_last_modified_datetime_utc
			THEN UPDATE
				SET sql_server_agent_job_name = SOURCE.sql_server_agent_job_name,
					job_create_datetime_utc = SOURCE.job_create_datetime_utc,
					job_last_modified_datetime_utc = SOURCE.job_last_modified_datetime_utc,
					is_enabled = SOURCE.is_enabled,
					is_deleted = SOURCE.is_deleted,
					job_category_name = SOURCE.job_category_name;




					UPDATE sql_server_agent_job
		SET is_enabled = 0,
			is_deleted = 1
	FROM dbo.sql_server_agent_job
	LEFT JOIN msdb.dbo.sysjobs
	ON sysjobs.Job_Id = sql_server_agent_job.sql_server_agent_job_id_guid
	WHERE sysjobs.Job_Id IS NULL;


	WITH CTE_NORMALIZE_DATETIME_DATA AS (
		SELECT
			sysjobhistory.job_id AS sql_server_agent_job_id_guid,
			CAST(sysjobhistory.run_date AS VARCHAR(MAX)) AS run_date_string, 
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_time AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_time AS VARCHAR(MAX)) AS run_time_string,
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_duration AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_duration AS VARCHAR(MAX)) AS run_duration_string,
			sysjobhistory.run_status,
			sysjobhistory.message,
			sysjobhistory.instance_id
		FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
		WHERE sysjobhistory.run_status = 0
		AND sysjobhistory.step_id = 0),
	CTE_GENERATE_DATETIME_DATA AS (
		SELECT
			CTE_NORMALIZE_DATETIME_DATA.sql_server_agent_job_id_guid,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 5, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 7, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 1, 4) AS DATETIME) +
			CAST(STUFF(STUFF(CTE_NORMALIZE_DATETIME_DATA.run_time_string, 5, 0, ':'), 3, 0, ':') AS DATETIME) AS job_start_datetime,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 1, 2) AS INT) * 3600 +
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 3, 2) AS INT) * 60 + 
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 5, 2) AS INT) AS job_duration_seconds,
			CASE CTE_NORMALIZE_DATETIME_DATA.run_status
				WHEN 0 THEN 'Failure'
				WHEN 1 THEN 'Success'
				WHEN 2 THEN 'Retry'
				WHEN 3 THEN 'Canceled'
				ELSE 'Unknown'
			END AS job_status,
			CTE_NORMALIZE_DATETIME_DATA.message,
			CTE_NORMALIZE_DATETIME_DATA.instance_id
		FROM CTE_NORMALIZE_DATETIME_DATA)
	SELECT
		CTE_GENERATE_DATETIME_DATA.sql_server_agent_job_id_guid,
		DATEADD(HOUR, @utc_offset, CTE_GENERATE_DATETIME_DATA.job_start_datetime) AS job_start_time_utc,
		DATEADD(HOUR, @utc_offset, DATEADD(SECOND, ISNULL(CTE_GENERATE_DATETIME_DATA.job_duration_seconds, 0), CTE_GENERATE_DATETIME_DATA.job_start_datetime)) AS job_failure_time_utc,
		ISNULL(CTE_GENERATE_DATETIME_DATA.message, '') AS job_failure_message,
		CTE_GENERATE_DATETIME_DATA.instance_id
	INTO #job_failure
	FROM CTE_GENERATE_DATETIME_DATA
	WHERE DATEADD(HOUR, @utc_offset, CTE_GENERATE_DATETIME_DATA.job_start_datetime) > DATEADD(MINUTE, -1 * @minutes_to_monitor, GETUTCDATE());



	WITH CTE_NORMALIZE_DATETIME_DATA AS (
		SELECT
			sysjobhistory.job_id AS sql_server_agent_job_id_guid,
			CAST(sysjobhistory.run_date AS VARCHAR(MAX)) AS run_date_string, 
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_time AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_time AS VARCHAR(MAX)) AS run_time_string,
			REPLICATE('0', 6 - LEN(CAST(sysjobhistory.run_duration AS VARCHAR(MAX)))) + CAST(sysjobhistory.run_duration AS VARCHAR(MAX)) AS run_duration_string,
			sysjobhistory.run_status,
			sysjobhistory.step_id,
			sysjobhistory.step_name,
			sysjobhistory.message,
			sysjobhistory.retries_attempted,
			sysjobhistory.sql_severity,
			sysjobhistory.sql_message_id,
			sysjobhistory.instance_id
		FROM msdb.dbo.sysjobhistory WITH (NOLOCK)
		WHERE sysjobhistory.run_status = 0
		AND sysjobhistory.step_id > 0),
	CTE_GENERATE_DATETIME_DATA AS (
		SELECT
			CTE_NORMALIZE_DATETIME_DATA.sql_server_agent_job_id_guid,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 5, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 7, 2) + '/' + SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_date_string, 1, 4) AS DATETIME) +
			CAST(STUFF(STUFF(CTE_NORMALIZE_DATETIME_DATA.run_time_string, 5, 0, ':'), 3, 0, ':') AS DATETIME) AS job_start_datetime,
			CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 1, 2) AS INT) * 3600 +
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 3, 2) AS INT) * 60 + 
				CAST(SUBSTRING(CTE_NORMALIZE_DATETIME_DATA.run_duration_string, 5, 2) AS INT) AS job_duration_seconds,
			CASE CTE_NORMALIZE_DATETIME_DATA.run_status
				WHEN 0 THEN 'Failure'
				WHEN 1 THEN 'Success'
				WHEN 2 THEN 'Retry'
				WHEN 3 THEN 'Canceled'
				ELSE 'Unknown'
			END AS job_status,
			CTE_NORMALIZE_DATETIME_DATA.step_id,
			CTE_NORMALIZE_DATETIME_DATA.step_name,
			CTE_NORMALIZE_DATETIME_DATA.message,
			CTE_NORMALIZE_DATETIME_DATA.retries_attempted,
			CTE_NORMALIZE_DATETIME_DATA.sql_severity,
			CTE_NORMALIZE_DATETIME_DATA.sql_message_id,
			CTE_NORMALIZE_DATETIME_DATA.instance_id
		FROM CTE_NORMALIZE_DATETIME_DATA)
	SELECT
		CTE_GENERATE_DATETIME_DATA.sql_server_agent_job_id_guid,
		DATEADD(HOUR, @utc_offset, CTE_GENERATE_DATETIME_DATA.job_start_datetime) AS job_start_time_utc,
		DATEADD(HOUR, @utc_offset, DATEADD(SECOND, ISNULL(CTE_GENERATE_DATETIME_DATA.job_duration_seconds, 0), CTE_GENERATE_DATETIME_DATA.job_start_datetime)) AS job_failure_time_utc,
		CTE_GENERATE_DATETIME_DATA.step_id AS job_failure_step_number,
		ISNULL(CTE_GENERATE_DATETIME_DATA.message, '') AS job_step_failure_message,
		CTE_GENERATE_DATETIME_DATA.sql_severity AS job_step_severity,
		CTE_GENERATE_DATETIME_DATA.retries_attempted,
		CTE_GENERATE_DATETIME_DATA.step_name,
		CTE_GENERATE_DATETIME_DATA.sql_message_id,
		CTE_GENERATE_DATETIME_DATA.instance_id
	INTO #job_step_failure
	FROM CTE_GENERATE_DATETIME_DATA
	WHERE DATEADD(HOUR, @utc_offset, CTE_GENERATE_DATETIME_DATA.job_start_datetime) > DATEADD(MINUTE, -1 * @minutes_to_monitor, GETUTCDATE());


	WITH CTE_FAILURE_STEP AS (
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY job_step_failure.sql_server_agent_job_id_guid, job_step_failure.job_failure_time_utc ORDER BY job_step_failure.job_failure_step_number DESC) AS recent_step_rank
		FROM #job_step_failure job_step_failure)
	INSERT INTO dbo.sql_server_agent_job_failure
		(sql_server_agent_job_id, sql_server_agent_instance_id, job_start_time_utc, job_failure_time_utc, job_failure_step_number, job_failure_step_name,
		 job_failure_message, job_step_failure_message, job_step_severity, job_step_message_id, retries_attempted, has_email_been_sent_to_operator)
	SELECT
		sql_server_agent_job.sql_server_agent_job_id,
		CTE_FAILURE_STEP.instance_id,
		job_failure.job_start_time_utc,
		CTE_FAILURE_STEP.job_failure_time_utc,
		CTE_FAILURE_STEP.job_failure_step_number,
		CTE_FAILURE_STEP.step_name AS job_failure_step_name,
		job_failure.job_failure_message,
		CTE_FAILURE_STEP.job_step_failure_message,
		CTE_FAILURE_STEP.job_step_severity,
		CTE_FAILURE_STEP.sql_message_id AS job_step_message_id,
		CTE_FAILURE_STEP.retries_attempted,
		0 AS has_email_been_sent_to_operator
	FROM #job_failure job_failure
	INNER JOIN dbo.sql_server_agent_job
	ON job_failure.sql_server_agent_job_id_guid = sql_server_agent_job.sql_server_agent_job_id_guid
	INNER JOIN CTE_FAILURE_STEP
	ON job_failure.sql_server_agent_job_id_guid = CTE_FAILURE_STEP.sql_server_agent_job_id_guid
	AND job_failure.job_failure_time_utc = CTE_FAILURE_STEP.job_failure_time_utc
	WHERE CTE_FAILURE_STEP.recent_step_rank = 1
	AND CTE_FAILURE_STEP.instance_id NOT IN (SELECT sql_server_agent_job_failure.sql_server_agent_instance_id FROM dbo.sql_server_agent_job_failure)
	AND sql_server_agent_job.job_category_name <> 'Unmonitored';


	INSERT INTO dbo.sql_server_agent_job_failure
		(sql_server_agent_job_id, sql_server_agent_instance_id, job_start_time_utc, job_failure_time_utc, job_failure_step_number, job_failure_step_name,
		 job_failure_message, job_step_failure_message, job_step_severity, job_step_message_id, retries_attempted, has_email_been_sent_to_operator)
	SELECT
		sql_server_agent_job.sql_server_agent_job_id,
		job_failure.instance_id,
		job_failure.job_start_time_utc,
		job_failure.job_failure_time_utc,
		0 AS job_failure_step_number,
		'' AS job_failure_step_name,
		job_failure.job_failure_message,
		'' AS job_step_failure_message,
		-1 AS job_step_severity,
		-1 AS job_step_message_id,
		0 AS retries_attempted,
		0 AS has_email_been_sent_to_operator
	FROM #job_failure job_failure
	INNER JOIN dbo.sql_server_agent_job
	ON job_failure.sql_server_agent_job_id_guid = sql_server_agent_job.sql_server_agent_job_id_guid
	WHERE job_failure.instance_id NOT IN (SELECT sql_server_agent_job_failure.sql_server_agent_instance_id FROM dbo.sql_server_agent_job_failure)
	AND NOT EXISTS (SELECT * FROM #job_step_failure job_step_failure WHERE job_failure.sql_server_agent_job_id_guid = job_step_failure.sql_server_agent_job_id_guid	AND job_failure.job_failure_time_utc = job_step_failure.job_failure_time_utc);

	WITH CTE_FAILURE_STEP AS (
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY job_step_failure.sql_server_agent_job_id_guid, job_step_failure.job_failure_time_utc ORDER BY job_step_failure.job_failure_step_number DESC) AS recent_step_rank
		FROM #job_step_failure job_step_failure)
	INSERT INTO dbo.sql_server_agent_job_failure
		(sql_server_agent_job_id, sql_server_agent_instance_id, job_start_time_utc, job_failure_time_utc, job_failure_step_number, job_failure_step_name,
		 job_failure_message, job_step_failure_message, job_step_severity, job_step_message_id, retries_attempted, has_email_been_sent_to_operator)
	SELECT
		sql_server_agent_job.sql_server_agent_job_id,
		CTE_FAILURE_STEP.instance_id,
		CTE_FAILURE_STEP.job_start_time_utc,
		CTE_FAILURE_STEP.job_failure_time_utc,
		CTE_FAILURE_STEP.job_failure_step_number,
		CTE_FAILURE_STEP.step_name AS job_failure_step_name,
		'' AS job_failure_message,
		CTE_FAILURE_STEP.job_step_failure_message,
		CTE_FAILURE_STEP.job_step_severity,
		CTE_FAILURE_STEP.sql_message_id AS job_step_message_id,
		CTE_FAILURE_STEP.retries_attempted,
		0 AS has_email_been_sent_to_operator
	FROM CTE_FAILURE_STEP
	INNER JOIN dbo.sql_server_agent_job
	ON CTE_FAILURE_STEP.sql_server_agent_job_id_guid = sql_server_agent_job.sql_server_agent_job_id_guid
	LEFT JOIN #job_failure job_failure
	ON job_failure.sql_server_agent_job_id_guid = CTE_FAILURE_STEP.sql_server_agent_job_id_guid
	AND job_failure.job_failure_time_utc = CTE_FAILURE_STEP.job_failure_time_utc
	WHERE CTE_FAILURE_STEP.recent_step_rank = 1
	AND job_failure.sql_server_agent_job_id_guid IS NULL
	AND CTE_FAILURE_STEP.instance_id NOT IN (SELECT sql_server_agent_job_failure.sql_server_agent_instance_id FROM dbo.sql_server_agent_job_failure);



	DECLARE @profile_name VARCHAR(MAX) = '?';
	DECLARE @email_to_address VARCHAR(MAX) = '?'; /* separate mail addresses by semicolon */
	DECLARE @email_subject VARCHAR(MAX);
	DECLARE @email_body VARCHAR(MAX);
	DECLARE @job_failure_count INT;
	SELECT
		@job_failure_count = COUNT(*)
	FROM dbo.sql_server_agent_job_failure
	WHERE sql_server_agent_job_failure.has_email_been_sent_to_operator = 0;
 
	-- Send an email to an operator if any new errors are found.
	IF EXISTS (SELECT * FROM dbo.sql_server_agent_job_failure WHERE sql_server_agent_job_failure.has_email_been_sent_to_operator = 0)
	BEGIN
		SELECT @email_subject = 'Failed Job Alert: ' + ISNULL(@@SERVERNAME, CAST(SERVERPROPERTY('ServerName') AS VARCHAR(MAX)));
		SELECT @email_body = 'At least one failure has occurred on ' + ISNULL(@@SERVERNAME, CAST(SERVERPROPERTY('ServerName') AS VARCHAR(MAX))) + ':
<html><body><table border=1>
<tr>
	<th colspan="6" bgcolor="#F29C89" align="left">Total Failed Jobs: ' + CAST(@job_failure_count AS VARCHAR(MAX)) + '</th>
</tr>
<tr>
	<th bgcolor="#F29C89">Job Name</th>
	<th bgcolor="#F29C89">Server Job Start Time</th>
	<th bgcolor="#F29C89">Server Job Failure Time</th>
	<th bgcolor="#F29C89">Failure Step Name</th>
	<th bgcolor="#F29C89">Job Failure Message</th>
	<th bgcolor="#F29C89">Job Step Failure Message</th>
</tr>';
		SELECT @email_body = @email_body + CAST((SELECT CAST(sql_server_agent_job.sql_server_agent_job_name AS VARCHAR(MAX)) AS 'td', '',
										  CAST(DATEADD(HOUR, -1 * @utc_offset, sql_server_agent_job_failure.job_start_time_utc) AS VARCHAR(MAX)) AS 'td', '',
										  CAST(DATEADD(HOUR, -1 * @utc_offset, sql_server_agent_job_failure.job_failure_time_utc) AS VARCHAR(MAX)) AS 'td', '',
										  sql_server_agent_job_failure.job_failure_step_name AS 'td', '',
										  sql_server_agent_job_failure.job_failure_message AS 'td', '',
										  sql_server_agent_job_failure.job_step_failure_message AS 'td'
		FROM dbo.sql_server_agent_job_failure
		INNER JOIN dbo.sql_server_agent_job
		ON sql_server_agent_job.sql_server_agent_job_id = sql_server_agent_job_failure.sql_server_agent_job_id
		WHERE sql_server_agent_job_failure.has_email_been_sent_to_operator = 0
		ORDER BY sql_server_agent_job_failure.job_failure_time_utc ASC
		FOR XML PATH('tr'), ELEMENTS) AS VARCHAR(MAX));
 
		SELECT @email_body = @email_body + '</table></body></html>';
		SELECT @email_body = REPLACE(@email_body, '<td>', '<td valign="top">');
 
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @profile_name,
			@recipients = @email_to_address,
			@subject = @email_subject,
			@body_format = 'html',
			@body = @email_body;
 
		UPDATE sql_server_agent_job_failure
			SET has_email_been_sent_to_operator = 1
		FROM dbo.sql_server_agent_job_failure
		WHERE sql_server_agent_job_failure.has_email_been_sent_to_operator = 0;
	END
END
GO

/*
source : https://www.sqlshack.com/reporting-and-alerting-on-job-failure-in-sql-server/
*/ 


