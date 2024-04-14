./create_vms.ps1 -cplaneCount 3 -workerCount 2 -vhdBasePath "E:\VMs\hyperv\" `
-switchName "bridged" -macPrefix "00155D1B2C" `
-haproxyImage "C:\Downloads\CentOS-7-x86_64-Minimal-2009.iso" `
-cplaneWorkersImage "C:\Downloads\ubuntu-22.04.4-live-server-amd64.iso" `
-prefix "k8s" -dryRun $false