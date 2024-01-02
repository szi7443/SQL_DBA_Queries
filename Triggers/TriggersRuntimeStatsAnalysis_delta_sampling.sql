USE EAM;


TRUNCATE TABLE DBAdminTools.dbo.triggertracker	;

/*
USE DBAdminTools;
CREATE TABLE TriggerTracker (
ID int IDENTITY(1,1) primary key,
[db_name]					VARCHAR(25) NOT NULL,
[trigger_name]				varchar(128) NOT NULL, 
execution_count				 bigint NOT NULL, 
total_worker_time			 bigint NOT NULL,
total_logical_reads			 bigint NOT NULL,
total_logical_writes		 bigint NOT NULL,
trigger_parent				 varchar(80) NOT NULL
)

TRUNCATE TABLE  dbadmintools.dbo.triggertracker;
 
ALTER TABLE dbadmintools.dbo.triggertracker ADD execution_count_delta            INT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD total_worker_time_delta          INT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD total_logical_reads_delta		 INT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD total_logical_writes_delta		 INT NULL;

 
ALTER TABLE dbadmintools.dbo.triggertracker ADD last_logical_reads            BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD last_logical_writes          BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD last_elapsed_time BIGINT NULL;

 
ALTER TABLE dbadmintools.dbo.triggertracker ADD last_logical_reads_delta            BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD last_logical_writes_delta          BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ADD last_elapsed_time_delta BIGINT NULL;

 
ALTER TABLE dbadmintools.dbo.triggertracker ALTER COLUMN execution_count_delta            BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ALTER COLUMN total_worker_time_delta          BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ALTER COLUMN total_logical_reads_delta		  BIGINT NULL;
ALTER TABLE dbadmintools.dbo.triggertracker ALTER COLUMN total_logical_writes_delta		  BIGINT NULL;

ALTER TABLE dbadmintools.dbo.triggertracker ADD [timestamp]						 datetime NULL;
*/


/*--------------------------------------------------------------------------------------------------------*/
USE DBAdminTools;
EXEC dbadmintools.dbo.sp_SaveTriggerRuntimeStats;
DROP PROCEDURE sp_SaveTriggerRuntimeStats;

CREATE OR ALTER  PROCEDURE sp_SaveTriggerRuntimeStats AS 
BEGIN
INSERT INTO DBAdminTools.dbo.triggertracker
(
[db_name]			
,[trigger_name]		
,execution_count		
,total_worker_time	
,total_logical_reads	
,total_logical_writes
,trigger_parent	
,execution_count_delta     
,total_worker_time_delta   
,total_logical_reads_delta
,total_logical_writes_delta
,last_logical_reads       
,last_logical_writes      
,last_elapsed_time
,last_logical_reads_delta       
,last_logical_writes_delta      
,last_elapsed_time_delta
,[timestamp]
)

SELECT t0.db_name 
, t0.trigger_name, 
t0.execution_count,t0.total_worker_time,t0.total_logical_reads,t0.total_logical_writes,
t0.trigger_parent,
				Cast(t0.execution_count AS BIGINT) -
                  Cast(tt.execution_count AS BIGINT) AS
                  execution_count_delta,
                  Cast(t0.total_worker_time AS BIGINT) -
                  Cast(tt.total_worker_time AS BIGINT)
                                                   AS total_worker_time_delta,
                  Cast(t0.total_logical_reads AS BIGINT) - Cast(
                  tt.total_logical_reads AS BIGINT)
                  AS total_logical_reads_delta,

                  Cast(t0.total_logical_writes AS BIGINT) - Cast(
                  tt.total_logical_writes AS BIGINT)
                  AS total_logical_writes_delta,

				  t0.last_logical_reads, t0.last_logical_writes, t0.last_elapsed_time,

				  Cast(t0.last_logical_reads AS BIGINT) - Cast(
                  tt.last_logical_reads AS BIGINT)
                  AS last_logical_reads_delta,

				  Cast(t0.last_logical_writes AS BIGINT) - Cast(
                  tt.last_logical_writes AS BIGINT)
                  AS last_logical_writes_delta, 

				  Cast(t0.last_elapsed_time AS BIGINT) - Cast(
                  tt.last_elapsed_time AS BIGINT)
                  AS last_elapsed_time_delta, t0.timestamp

FROM

(SELECT /*epa.*,*/ Db_name(tstats.database_id)
                  AS
                  [db_name],
                  Object_name(tstats.object_id)
                  AS trigger_name,
                  Sum(tstats.execution_count)
                  AS execution_count,
                  Sum(tstats.total_worker_time)
                  AS total_worker_time,
                  Sum(tstats.total_logical_reads)
                  AS total_logical_reads,
                  Sum(tstats.total_logical_writes)
                  AS total_logical_writes,

				   Sum(tstats.last_logical_reads)
                  AS last_logical_reads,
				   Sum(tstats.last_logical_writes)
                  AS last_logical_writes,
				   Sum(tstats.last_elapsed_time)
                  AS last_elapsed_time,



                  /* Why Summing is necessary? 
                  https://dba.stackexchange.com/questions/334479/dmv-sys-dm-exec-trigger-stats-duplicate-entries?noredirect=1#comment651162_334479
                  */
                  Object_name(trgs.parent_id)
                  AS trigger_parent,
                  Getdate()
                  AS [timestamp]
FROM   sys.dm_exec_trigger_stats tstats
       INNER JOIN sys.triggers trgs
               ON tstats.object_id = trgs.object_id
       /*OUTER APPLY sys.dm_exec_plan_attributes(tstats.plan_handle) AS epa*/

               
--WHERE  Db_name(tstats.database_id) = 'DB of your choice'

GROUP  BY Db_name(tstats.database_id),
          Object_name(trgs.parent_id),
          Object_name(tstats.object_id)

) t0  
       LEFT JOIN (SELECT *
                  FROM   dbadmintools.dbo.triggertracker
                  WHERE  [timestamp] = (SELECT TOP 1 [timestamp]
                                        FROM   dbadmintools.dbo.triggertracker
                                        ORDER  BY [timestamp] DESC)) tt
              ON tt.db_name = t0.db_name AND tt.trigger_name = t0.trigger_name AND tt.trigger_parent = t0.trigger_parent


END



