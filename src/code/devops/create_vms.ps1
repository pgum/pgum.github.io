<#
.SYNOPSIS
This script creates set of virtual machines supposed to handle k8s cluster. 
It creates one load balancer, control plane nodes and worker nodes.

.DESCRIPTION
This script creates one load balancer, set of control plane nodes and set of worker nodes. 
It uses Hyper-V PowerShell module to create VMs. 
The script can be run in dry run mode to see what VMs would be created.
Use -dryRun $false to create the VMs.

.PARAMETER cplaneCount
Amount of c-plane nodes to create. Control plane nodes will run k8s master components.

.PARAMETER workerCount
Amount of worker nodes to create. Worker nodes are the nodes that will run the application workloads.

.PARAMETER vhdBasePath
Path to store the VHD files.

.PARAMETER switchName
Bridge name to connect the VMs to.

.PARAMETER macPrefix
First 10 characters of MAC address. 
To this prefix, the script will add a number from 0 to 255 (00-FF).
Defaults to 00155D0A0A. 

.PARAMETER haproxyImage
Image location for haproxy VM. This VM will be used as a load balancer. 

.PARAMETER cplaneWorkersImage
Image location for cplane and worker nodes.

.PARAMETER prefix
Prefix which will be added to the VM names. Defaults to 'k8s'.

.PARAMETER dryRun
If set to true, the script will only print what VMs would be created. 
If set to false, the script will create the VMs.

.EXAMPLE
create_vms.ps1 -cplaneCount 3 -workerCount 2 -vhdBasePath "E:\VMs\hyperv\" `
-switchName "bridged" -macPrefix "00155D1B2C" `
-haproxyImage "C:\Downloads\CentOS-7-x86_64-Minimal-2009.iso" `
-cplaneWorkersImage "C:\Downloads\ubuntu-22.04.4-live-server-amd64.iso" `
-prefix "borgchan" -dryRun $false

.NOTES
Additional notes about the script.
#>

param (
    [Parameter(Mandatory=$false, HelpMessage="Number of control plane nodes to create.")]
    [ValidateRange(3, 15)]
    [int]$cplaneCount=3,
    
    [Parameter(Mandatory=$false, HelpMessage="Number of worker nodes to create.")]
    [ValidateRange(2, 64)]
    [int]$workerCount=2,
    
    [Parameter(Mandatory=$false, HelpMessage="Path to VHD file. Defaults to E:\VMs\hyperv\")]
    [string]$vhdBasePath = "E:\VMs\hyperv\",
    
    [Parameter(Mandatory=$false, HelpMessage="Virtual switch name. Defaults to bridged.")]
    [string]$switchName = "bridged",

    [Parameter(Mandatory=$false, HelpMessage="First 10 characters of MAC address. Defaults to 00155D0A0A.")] #00:15:5D:0A:0A:
    [string]$macPrefix = "00155D0A0A",

    [Parameter(Mandatory=$false, HelpMessage="Image location for haproxy.")]
    [string]$haproxyImage = "E:\VMs\images\CentOS-7-x86_64-Minimal-2009.iso",
    
    [Parameter(Mandatory=$false, HelpMessage="Image location cplane and workers.")]
    [string]$cplaneWorkersImage = "E:\VMs\images\ubuntu-22.04.4-live-server-amd64.iso",

    [Parameter(Mandatory=$false, HelpMessage="Prefix for VM names. Defaults to 'k8s'.")]
    [string]$prefix="k8s",
    
    [Parameter(Mandatory=$false, HelpMessage="Should this execution be a dry run. Defaults to true.")]
    [bool]$dryRun=$true
)

$macAddressCounter = -1 # Because of we increment the counter before returning the value, we start from -1
# Global variable we increment and return in generator
# Generates MAC addresses from 0-FF (255)... and beyond. Don't run this script more than 255 times. 
# Also, don't get attached to it. It's just a simple example.
$macAddressGenerator = {
    $script:macAddressCounter++
    $script:macAddressCounter
}
function CreateSingleVM($name, $image, $cpu=2, $ram=4, $hdd=40) {
    $vhdFilePath = $vhdBasePath + $name + '.vhdx'
    $macNumber = &$macAddressGenerator
    $vmMac = $macPrefix+$macNumber.ToString("X2")
    $vmRam = $ram * 1GB
    $vmHdd = $hdd * 1GB
    if($dryRun -eq $true){
        Write-Host "Dry run: Would create VM name: $name, MAC: $vmMac, CPU: $cpu, RAM: $vmRam, HDD: $vmHdd. Image path: $image."
        return
    } 
    New-VM -Name $name -MemoryStartupBytes $vmRam -Generation 1 -NewVHDPath $vhdFilePath -NewVHDSizeBytes $vmHdd -SwitchName $switchName
    Set-VMDvdDrive -VMName $name -Path $image
    Set-VMProcessor -VMName $name -Count $cpu
    Set-VMNetworkAdapter -VMName $name -StaticMacAddress $vmMac
    Set-VM -Name $name -CheckpointType Disabled
    Set-VMMemory -VMName $name -DynamicMemoryEnabled $false
    Write-Host "Created VM name: $name, MAC: $vmMac, CPU: $cpu, RAM: $vmRam, HDD: $vmHdd. Image path: $image."
}
function getName($name){
    if($prefix -eq $null -or $prefix -eq ""){ return $name } else {
        return "{0}-{1}" -f ($prefix, $name)}
}
function setNameWithCounter($name,$counter){
    $vmCoreName = getName($name)
    return ("{0}-{1}" -f ($vmCoreName, $counter.ToString()))
}
function CreateLoadBalancer($name) {
    Write-Host "Creating loadbalancer VM:"
    $loadBalancerName = getName($name)
    CreateSingleVM $loadBalancerName $haproxyImage 2 2 20
}
function CreateControlPlane($name, $count) {
    Write-Host "Creating control plane VMs [$count]:"
    for ($i = 0; $i -lt $count; $i++) {
        $vmName = setNameWithCounter $name $i
        CreateSingleVM $vmName $cplaneWorkersImage 2 4 40
    }
}
function CreateWorkers($name, $count) {
    Write-Host "Creating worker nodes VMs [$count]:"
    for ($i = 0; $i -lt $count; $i++) {
        $vmName = setNameWithCounter $name $i
        CreateSingleVM $vmName $cplaneWorkersImage 2 4 40
    }
}

Write-Host "Creating VMs: load balancer node, $cplaneCount control plane nodes and $workerCount worker nodes. dryRun: $dryRun"
if($dryRun -eq $false){
    Write-Host "This is an actual run. VMs will be created."
} 

CreateLoadBalancer 'haproxy'
CreateControlPlane 'cplane' $cplaneCount
CreateWorkers 'worker' $workerCount
