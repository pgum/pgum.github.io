---
category: devops
title: Part 1 - Preparation with Hyper-V on Windows
tags: [devops, linux, hyperv, centos, ubuntu, ansible, haproxy, kubespray, kubernetes]
key-points: 
  - Setup Hyper-V on Windows machine
  - Create a bunch of VMs, configuring them
  - Possible upgrades in procedure
--- 

## Goal
During this tutorial we will create first layer of our architecture. The goal here is to have following:
* virtual switch, named `bridged`
* 1 load-balancer node, `haproxy` - runs on `CentOS-7-x86_64-Minimal-2009` - IP: `10.0.10.200` - MAC: `00:15:5D:0A:0A:00`
* 3 main nodes, `cplane-0..2` - run on `ubuntu-22.04.4-live-server-amd64` - IP: `10.0.10.20{1..3}` - MAC: `00:15:5D:0A:0A:0{1..3}`
* 2 worker nodes, `worker-0..1` - run on `ubuntu-22.04.4-live-server-amd64` - IP: `10.0.10.20{4..5}` - MAC: `00:15:5D:0A:0A:0{4..5}`
We are going to use Hyper-V for it. Hyper-V is a native hypervisor for Windows. It was first released alongside Windows Server 2008, and has been available on most versions of Windows since Windows 8. Hyper-V allows you to create and manage virtual machines on your Windows system. However, it's only available on 64-bit versions of Windows and requires specific hardware capabilities. 

I use MAC addresses to assign IP for those machines on my home router. 

## Setup Hyper-V on Windows machine

## Administrative privileges
To run a command as an administrator in Windows, you need to open PowerShell with administrative privileges. Here are the steps:

Press the Windows key, type PowerShell into the search bar.
Right-click on Windows PowerShell in the search results, and select Run as administrator.
In the administrative PowerShell session we will write our commands, so that we wont need to click thru the interface of Hyper-V Manager.

## Code
{% code devops/create_vmswitch.ps1 lang='powershell' cfrom=2 cto=5%}
## Shell
{% shell devops/create_vmswitch.ps1 lang='powershell' %}
## Output
{% output devops/create_vmswitch.ps1 title="Bardzo ważny output z własną nazwą" %}

## Create virtual switch
In the administrative PowerShell session, run your command:


{% code devops/create_vmswitch.ps1 lang='powershell' cfrom=13 cto=13 shell=true %}  

dupa

{% shell devops/create_vmswitch.ps1 nolink=true title="dupa szatana" %}  

Here are the important bits
{% code devops/create_vms.ps1 lang="powershell" cfrom=93 cto=96 shell=false log=false %}

This one generates unique MAC addessess for our VMs. We use them later.  
Then we generate the VM in this part.
{% code devops/create_vms.ps1 lang="powershell" cfrom=108 cto=114 shell=false log=false noheader=true %}

So that we can execute the script
{% shell devops/create_vms.ps1 lang="powershell" nosource=true shell=true log=true %}

A to tylko żeby se zobaczyć lol
{% code devops/create_vms.ps1 lang="powershell" clines="3,5,7" shell=false log=false %}

## Create a bunch of VMs, configuring them
## Spraying k8s cluster on top
## Possible upgrades in procedure
