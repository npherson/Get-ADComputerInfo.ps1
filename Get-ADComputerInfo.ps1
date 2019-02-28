<#
    .SYNOPSIS
        Used to collect key information about Computer objects in Active Directory.

    .DESCRIPTION
        Use the Get-ADComputerinfo.ps1 script to output details about all the Computer objects in Active Directory to a CSV file.    

        The script will attempt to query all domains in the forest that you are connected to.

        Nope, this script doesn't have forest/domain parameters built it... feel free to make contributions on GitHub.

        You can schedule this script to run as a scheduled task with any domain user with 'read' rights in the directory.
        SCHTASKS /Create /TN "ConfigMgr Start-AICategorization" /SC Daily /TR "POWERSHELL.EXE -ExecutionPolicy Bypass -File C:\Scripts\Get-AdComputerInfo.ps1" /RU domain\AnyUserWithReadRights /RP *

    .NOTES
        Author  : Nash Pherson
        Email   : napherso@microsoft.com
        Twitter : @KidMytsic  https://twitter.com/kidmystic        
        
    .LINK
        https://gallery.technet.microsoft.com/Get-ADComputerInfops1-b5b3e656
    
    .LINK
        https://github.com/npherson/Get-ADComputerInfo.ps1

#>



# Set the name of the output CSV file...
$output = "CompList-$(get-date -f yyyy-MM-dd-hh.mm.ss).csv"

# Check to see if ActiveDirectory Module is installed...
If (!(Get-Module -ListAvailable -Name ActiveDirectory))
    {
        # No AD Module installed... End user needs to install RSAT first
        If ([System.Environment]::OSVersion.Version.Build -lt 17682) {
            Write-Warning "To use this script, you must install the Active Directory Module for PowerShell (part of RSAT).";Break
        }
 
        # No AD Module installed... Try to install it via Features on Demand (Win 10 Build 17682 and above)
        Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
        If (!(Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Warning "To use this script, you must install the Active Directory Module for PowerShell. Could not install RSAT for you.";Break
        }
    }   

# Load the ActiveDirctory module...
If (!(Get-Module ActiveDirectory)) {Import-Module ActiveDirectory}

# Enumerate domains this user/device can see...
$Domains = (Get-ADForest).Domains

# Find all computer objects from all domains...
$AllComputers = @()
Foreach ($i in $Domains)
    {
        $Computers = Get-ADComputer -Filter {OperatingSystem -Like "*Windows*"} -Server $i -Properties lastlogontimestamp,enabled,whenCreated,operatingSystem,operatingSystemVersion,operatingSystemServicePack,distinguishedName,description | `
        select-object Name,@{Name="lastLogonTimestamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}},Enabled,operatingSystem,operatingSystemVersion,operatingSystemServicePack,distinguishedName,Description,@{Name="Domain"; Expression={$i}}
        $AllComputers += $Computers
    }

# Strip out the special character from Server 2008 and Vista objects...
$AllComputers = $Allcomputers -replace "\?",""

# Write computer object data to CSV file...
$AllComputers | Export-CSV $output -NoClobber -NoTypeInformation
