param (
    [Parameter(Mandatory=$true, HelpMessage="Virtual switch name. Defaults to bridged.")]
    [ValidateNotNullOrEmpty()]
    [string]$Name = "bridged",
    
    [Parameter(Mandatory=$false, HelpMessage="NetAdapter name. Defaults to Ethernet.")]
    [string]$NetAdapterName = "Ethernet",
    
    [Parameter(Mandatory=$false, HelpMessage="Do host OS have access to the network boud to this switch. Defaults to true.")]
    [bool]$AllowManagementOS = $true,

    [Parameter(Mandatory=$false, HelpMessage="Do dry run. Defaults to true.")]
    [bool]$dryRun=$true
)
if($dryRun -eq $true) {
    Write-Host "Dry run: Would create a virtual switch named $switchName, with netAdapter name: $netAdapterName, and AllowManagementOS: $allowManagementOS."
    exit
}
New-VMSwitch -Name "$Name" -NetAdapterName "$NetAdapterName" -AllowManagementOS $AllowManagementOS
