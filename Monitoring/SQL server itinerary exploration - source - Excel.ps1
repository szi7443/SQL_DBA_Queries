import-module importexcel
import-module dbatools
$excel = Import-Excel 'C:\MyWork\SQLServersList.xlsx'
$Array = @()
$Servers = @{}
#$q= 0
foreach($server in $excel) {
    #$q++
    $pk = Get-DbaProductKey -computername $server.'SQL Server' -ErrorAction SilentlyContinue 
    <# instance count is not used anywhere, it's only for demonstration here #>
    #$instance_count = ($pk | Measure-Object).Count
    $os = Get-DBAOperatingsystem $server.'SQL Server'
    $Instances = @()
    $Versions = @()
    $Editions = @()
    $servername = $($server.'SQL Server').ToString()
    Write-Host -BackgroundColor DarkGreen $servername
    foreach($i in $pk) {
        $Instances+= $i.sqlinstance
        $Versions += $i.version
        $Editions += $i.Edition
    }

    $Servers.Add($servername,@($Instances,$Versions,$Editions,$os.OSVersion))

   <# if($q -gt 2) {
        break
    }#>
}

write-host "-------------------"
foreach($key in  $Servers.Keys) {
    $m = 0
    write-host $("ServerName:"+$key.ToString() + " " + "OS: " +$Servers[$key][3])
    for($q=0; $q -lt $Servers[$key][0].Length;$q++) {
        write-host $("Instance: " + $Servers[$key][0][$q].ToString() + "; Versions: " + $Servers[$key][1][$q].ToString() + "; Editions:" + $Servers[$key][2][$q].ToString()) 
    }
#    write-host $Servers[$key][3]
}
