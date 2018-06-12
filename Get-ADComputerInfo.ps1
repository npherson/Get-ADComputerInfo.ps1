# Requires the following component is installed:
# Remote Server Administration Tools > Active Directory Module for Powershell
# Nash Pherson 2017-03-15
# 

# Set the name of the output CSV file...
$output = "CompList-$(get-date -f yyyy-MM-dd-hh.mm.ss).csv"

# Check to see if ActiveDirectory module is installed...
If (!(Get-Module -ListAvailable -Name ActiveDirectory)) {Write-Warning "To use this script, you must install the Active Directory Module for PowerShell.";Break}

# Load the ActiveDirctory module...
If (!(Get-Module ActiveDirectory)) {Import-Module ActiveDirectory}

# Enumerate domains this user/device can see...
$Domains = (Get-ADForest).Domains

# Find all computer objects from all domains...
$AllComputers = @()
Foreach ($i in $Domains)
    {
        $Computers = Get-ADComputer -Filter {OperatingSystem -Like "*Windows*"} -Server $i -Properties lastlogontimestamp,enabled,operatingSystem,operatingSystemVersion,operatingSystemServicePack,distinguishedName,description | `
        select-object Name,@{Name="lastLogonTimestamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},Enabled,operatingSystem,operatingSystemVersion,operatingSystemServicePack,distinguishedName,Description,@{Name="Domain"; Expression={$i}}
        $AllComputers += $Computers
    }

# Write computer object data to CSV file...
$AllComputers | Export-CSV $output -NoClobber -NoTypeInformation