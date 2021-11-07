 SELECT TOP 50 creation_date = Cast(creation_time AS DATE),
              creation_hour = CASE
                                WHEN Cast(creation_time AS DATE) <>
                                     Cast(Getdate() AS DATE)
                              THEN 0
                                ELSE Datepart(hh, creation_time)
                              END,
              Sum(1) AS plans
FROM   sys.dm_exec_query_stats
GROUP  BY Cast(creation_time AS DATE),
          CASE
            WHEN Cast(creation_time AS DATE) <> Cast(Getdate() AS DATE) THEN 0
            ELSE Datepart(hh, creation_time)
          END
ORDER  BY 1 DESC,
          2 DESC  