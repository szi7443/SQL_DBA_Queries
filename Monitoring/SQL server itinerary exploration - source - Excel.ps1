import-module importexcel
import-module dbatools
$excel = Import-Excel 'C:\MyWork\SQLServersList.xlsx'
$Array = @()
$Servers = @{}
#$q= 0
foreach($server in $excel) {
    #$q++
    <# instance count is not used anywhere, it's only for demonstration here #>
    #$instance_count = ($pk | Measure-Object).Count
    $instances = (Get-DbaProductKey -ComputerName  $server.'SQL Server' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | select sqlinstance)
    $icount = ($instances | measure-object).Count
    
    Write-Host $server.'SQL Server'
    if($icount -gt 0) {
        for($q = 0;$q -lt $icount;$q++ ) {
        write-host $instances[$q].SqlInstance
        Get-DbaInstanceProperty -sqlinstance $instances[$q].SqlInstance | Where-Object {$_.Name -like 'HostDistribution' -or $_.Name -like 'Processors' -or  $_.Name -like 'VersionMajor' -or   $_.Name -like 'Edition'} | select name, value, ComputerName, InstanceName

        }
    }
}
