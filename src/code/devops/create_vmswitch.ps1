param (
    [Parameter(Mandatory=$true, HelpMessage="Virtual switch name. Defaults to bridged.")]
    [ValidateNotNullOrEmpty()]
    [string]$switchName = "bridged",

    [Parameter(Mandatory=$false, HelpMessage="Do dry run. Defaults to true.")]
    [bool]$dryRun=$true
)
if($dryRun -eq $true) {
    Write-Host "Dry run: Would create a virtual switch named $switchName."
    exit
}
New-VMSwitch -Name "$switchName" -NetAdapterName Ethernet -AllowManagementOS $true
