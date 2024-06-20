
import-module importexcel
import-module dbatools
<# make sure to install SQL server module in powershell before running this script: 

as per my testing, default version of the sqlserver module is broken, so: 
install-module sqlserver -RequiredVersion 21.1.18256
 #>
$excel = Import-Excel 'your_excelsheet.xlsx'
$Array = @()
$Servers = @{}
#$q= 0
$query = "
DECLARE @ProductVersion NVARCHAR(30)
 
SET @ProductVersion = CONVERT(NVARCHAR(20),SERVERPROPERTY('ProductVersion')) 
 
SELECT @ProductVersion = 
      CASE SUBSTRING(@ProductVersion,1,4)
         WHEN '16.0' THEN 'SQL Server 2022'
         WHEN '15.0' THEN 'SQL Server 2019'
         WHEN '14.0' THEN 'SQL Server 2017' 
         WHEN '13.0' THEN 'SQL Server 2016' 
         WHEN '12.0' THEN 'SQL Server 2014' 
         WHEN '11.0' THEN 'SQL Server 2012' 
         WHEN '10.5' THEN 'SQL Server 2008 R2' 
         WHEN '10.0' THEN 'SQL Server 2008'  
      END
 
SELECT @@SERVERNAME AS SQLServerName, 
       @ProductVersion AS ProductVersion,
       SERVERPROPERTY('Edition') AS Edition,
       SERVERPROPERTY('ProductLevel') AS ProductLevel,
       SERVERPROPERTY('ProductUpdateLevel') AS ProductUpdateLevel,
       SERVERPROPERTY('ProductVersion') AS Version,
       cpu_count/hyperthread_ratio AS [Sockets], 
       hyperthread_ratio AS [CoresPerSocket], 
       cpu_count AS [Cores] 
FROM sys.dm_os_sys_info
GO
"

function Invoke-SQL {
    param(
        [string] $dataSource = ".\SQLEXPRESS",
        [string] $database = "MasterData",
        [string] $sqlCommand = $(throw "Please specify a query.")
      )

    $connectionString = "Data Source=$dataSource; " +
            "Integrated Security=SSPI; " +
            "Initial Catalog=$database"

    $connection = new-object system.data.SqlClient.SQLConnection($connectionString)
    $command = new-object system.data.sqlclient.sqlcommand($sqlCommand,$connection)
    $connection.Open()
    
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataSet) | Out-Null
    
    $connection.Close()
    $dataSet.Tables

}


foreach($server in $excel) {
    #$q++

    <# instance count is not used anywhere, it's only for demonstration here #>
    #$instance_count = ($pk | Measure-Object).Count
    $instances = (Get-DbaProductKey -ComputerName  $server.'SQL Server' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | select sqlinstance)
    $icount = ($instances | measure-object).Count
    Write-Host $server.'SQL Server'
    if($icount -gt 0) {
        for($q = 0;$q -lt $icount;$q++ ) {
        $instances[$q].SqlInstance | Out-File DBInventory.txt -Append
        #Get-DbaInstanceProperty -sqlinstance $instances[$q].SqlInstance | Where-Object {$_.Name -like 'HostDistribution' -or $_.Name -like 'Processors' -or  $_.Name -like 'VersionMajor' -or   $_.Name -like 'Edition'} | select name, value, ComputerName, InstanceName | Format-Table -AutoSize
       
        #write-host $instances[$q].SqlInstance.ToString()
        #Invoke-Sqlcmd -serverinstance $instances[$q].SqlInstance -query $query -TrustServerCertificate | Format-Table | Out-File DBInventory.txt -Append
        $output = Invoke-SQL -dataSource $instances[$q].SqlInstance.ToString() -sqlCommand $query -database "master"
        
        $output | Format-Table | Out-File DBInventory.txt -Append
        $rs = New-PSSession -ComputerName $server.'SQL Server'
        $remotelastexitcode = Invoke-Command  -Session $rs -ScriptBlock {
        $vCores = Get-WmiObject Win32_Processor | Measure -Property  NumberOfCores -Sum
        $vCores = $vCores.Sum
        $vLogicalCPUs = Get-WmiObject Win32_Processor | Measure -Property  NumberOfLogicalProcessors -Sum
        $vLogicalCPUs = $vLogicalCPUs.sum
        $enabled = 0;
        if ($vLogicalCPUs -gt $vCores) { 
       $HT=“Hyper Threading: Enabled”
       $enabled = 1
    } 
   else {  $HT=“Hyper Threading: Disabled”
    $enabled = 0
    } 
    return $enabled        }
    "hyperthreading enabled --> "+$remotelastexitcode.ToString() | Out-File DBInventory.txt -Append
    '-'*60 | Out-File DBInventory.txt -Append
    remove-pssession $rs
        }
    }
}
