---
category: devops
title: Part 1 - Preparation with Hyper-V on Windows
tags: [devops, linux, hyperv, centos, ubuntu, ansible, haproxy, kubespray, kubernetes]
key-points: 
  - Setup Hyper-V on Windows machine
  - Create a bunch of VMs, configuring them
  - Possible upgrades in procedure
toc: true

--- 
During this tutorial we will create first layer of our architecture. The goal here is to have following:
* virtual switch, named `bridged`, that uses our physical netword device and serves as a bridge for VM network adapters
* 1 load-balancer node, `haproxy` - runs on CentOS 7 - IP: `10.0.10.200` - MAC: `00:15:5D:0A:0A:00`
* 3 main nodes, `cplane-0..2` - run on Ubuntu 22.04 - IP: `10.0.10.20{1..3}` - MAC: `00:15:5D:0A:0A:0{1..3}`
* 2 worker nodes, `worker-0..1` - run on Ubuntu 22.04 - IP: `10.0.10.20{4..5}` - MAC: `00:15:5D:0A:0A:0{4..5}`

```
  ┌───────────────┐                     ┌───────────────┐                 
  │  10.0.10.201  │                     │  10.0.10.204  │                 
  │  ┌────────────┴──┐     ┌─────────┐  │  ┌────────────┴──┐             
  │  │  10.0.10.202  │     │ ....200 │  │  │  10.0.10.205  │             
  │  │  ┌────────────┴──┐  │ HAproxy │  │  │               │             
  └──┤  │  10.0.10.203  │  │         │  └──┤ Worker nodes  │             
     │  │               │  └─────────┘     │               │             
     └──┤ C-plane nodes │                  └───────────────┘             
        │               │                                                 
        └───────────────┘                                                 
```

We are going to use Hyper-V for it. Hyper-V is a native hypervisor for Windows. It was first released alongside Windows Server 2008, and has been available on most versions of Windows since Windows 8. Hyper-V allows you to create and manage virtual machines on your Windows system. However, it's only available on 64-bit versions of Windows and requires specific hardware capabilities. 


## Before we start

### Networking

I use MAC addresses to assign IP for those machines on my home router. Unfortunately I had to click manually to assign MACs with IPs. If you are more lucky with your router, and can run OpenWRT, you can use something like that: 
```bash
COUNTER_HEX=$(printf '%x\n' $COUNTER)
uci add dhcp host
uci set dhcp.@host[-1].ip=${IP_ADDRESS_PREFIX}${COUNTER}
uci set dhcp.@host[-1].mac=${MAC_ADDRESS_PREFIX}${COUNTER_HEX}
uci commit dhcp
/etc/init.d/dnsmasq restart
```
with filling out the rest of the script for yourself :smile:  

What is more, we utilize `/etc/hosts` Windows file located in `%SystemRoot%\System32\drivers\etc\hosts`. Adding following lines will make our VMs recognizable by descriptive name instead of IP address:
```r
10.0.10.200 haproxy.k8s.local haproxy 
10.0.10.201 cplane-0.k8s.local cplane-0
10.0.10.202 cplane-1.k8s.local cplane-1
10.0.10.203 cplane-2.k8s.local cplane-2
10.0.10.204 worker-0.k8s.local worker-0
10.0.10.205 worker-1.k8s.local worker-1
```

WSL generate `/etc/hosts` file by default from what is set on Windows. To disable this, edit `/etc/wsl.conf` with editor of choice with `sudo`, and add following entry:
```ini
[network]
generateHosts = False
```
Be aware that you would need to keep `hosts` file on your own, but it will never get overwritten unexpectedly by WSL.

Fun fact, my router for some reason did not liked one of the IP assignments, and seemed to ignore my kind request to cooperate. If you are for any reason in similar situation, remember, that you can always change `netcfg` on VM for it use manual IP assignment. For example `/etc/netplan/01-netcfg.yaml` that could do the work:
```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.0.10.201/16]
      gateway4: 10.0.10.254
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
```

### Get the OS images

For this setup we will use:  

* [CentOS 7 Minimal 2009](http://isoredirect.centos.org/centos/7/isos/x86_64/) - `CentOS-7-x86_64-Minimal-2009`- for HAproxy VM.
* [Ubuntu 22.04 Server](https://releases.ubuntu.com/jammy/) - `Ubuntu-22.04.4-live-server-amd64` - for  cplane and worker VMs.  

Any linux distro will work I guess, these are the ones I chose to do this exercise on.

### Free up your storage

I assume 40GB storage per cplane and worker node. I advise setting no less than 20GB. I experienced failures in setup or later in running the system, that it going lower than 20 gigs is risky.  
HAproxy server can be light and tiny.

### Close Chrome and Discord for a second

Fun fact, Hyper-V will throw error if it cannot reserve required amount of memory in the system. How do I know? I use (1\*1)+(3\*2)+(2\*4) = 15gigs for this setup, and had 32gigs in the system before upgrading to 64. So, long story short, having Chrome with 50+ tabs open, alongside Discord and VSCode adn Steam and such is *not good* for your PC rig, and *will* prevent VMs to start. Quick "fix" would be to turn on your heavy memory stuff *after* you start all VMs. 

### Administrative privileges in Windows

To run a command as an administrator in Windows, you need to open PowerShell with administrative privileges. Here are the steps:

Press the Windows key, type PowerShell into the search bar.  
Right-click on Windows PowerShell in the search results, and select Run as administrator.  
In the administrative PowerShell session we will write our commands, so that we wont need to click thru the interface of Hyper-V Manager.  

### Generate ssh keys

Get yourself `ssh-keygen` and generate key pair to use for SSH login on baremetal. This key will be used for Ansible user `borg`. Oh, yea, you would want to have `ansible` installed in your WSL.

## Setup Hyper-V infrastructure

Alright, after all preparations in place we can create our virtual switch, and VMs.

Enable `RemoteSigned` policy, so that you can run locally-created scripts without digital signature.

{% shell devops/enable_remotesigned noout=true %}

### Create virtual switch

In the administrative PowerShell session, run your command:

{% shell devops/create_vmswitch_oneliner lang='powershell' %}

If we want to be fancy, and we like to do small thingies, we may think - let's automate that. Yeah, sure let's to this. Basically what we would do, is to wrap this command and add out default values, all amounting to having following line parametrised.

{% code devops/create_vmswitch.ps1 cfrom=19 cto=19 %}  

Then, we can check with [documentation](https://learn.microsoft.com/en-us/powershell/module/hyper-v/new-vmswitch) that our script don't cover 70% of the available flags. But it was a nice example on how to write passable powershell script.

Cool! Anyway, whatever method we chose, we end up with network bridge for our little server farm so we can go on.

### Create a bunch of VMs, configuring them

So now we have our network ready, and our host capable of carrying the task we can create our VMs.  
For that we can click thru Hyper-V interface, or again, use powershell.

{% shell devops/create_vms.ps1 lang="powershell" noout=true %}

Here are the important bits of the script:

{% code devops/create_vms.ps1 lang="powershell" cfrom=88 cto=91 noshell=true noout=true %}

This one generates unique MAC addessess for our VMs.  
Then we generate the VM in this part with `function CreateSingleVM($name, $image, ...)`  
{% code devops/create_vms.ps1 lang="powershell" cfrom=101 cto=108 noshell=true noout=true %}

We use this function later in `CreateLoadBalancer`, `CreateControlPlane`, and `CreateWorkers` functions.
{% code devops/create_vms.ps1 lang="powershell" cfrom=143 cto=145 noout=true noshell=true %}

## Install OS on VMs

During install, I have created user `killme`. Everything else except that and hostname I left as is.

### HAProxy

For `haproxy.k8s.local` we go thru CentOS install.  
HAProxy is a free, very fast, and reliable solution offering high availability, load balancing, and proxying for TCP and HTTP-based applications. It is particularly suited for web sites crawling under very high loads while needing persistence or Layer7 processing.  

This node is super light and meant to host haproxy software that function as reverse proxy for control plane node. This way all requests go to `haproxy.k8s.local` node, and it forwards them to one of control plane nodes.

We need to create configuration file for HAProxy, that will reside in `/etc/haproxy/haproxy.cfg`

{% code devops/ansible/haproxy.cfg noout=true noshell=true cfrom=20 cto=24 %}
We create frontend named `kube-apiserver` that binds on port 8383 in tcp. It will forward whatever comes to backend named `kube-apiserver`.

{% code devops/ansible/haproxy.cfg noout=true noshell=true cfrom=26 cto=34 %}
Here we create backend we referenced just before. What is worth notice here is `balance roundrobin` and `server` definitions.

The `balance` directive is used to set the load balancing algorithm to be used in a backend. This algorithm decides which server, from a backend, will be selected to process each incoming request. The `roundrobin` algorithm is one of the simplest and most commonly used algorithms. It distributes client requests across all servers sequentially. 

The lines of code define three servers that HAProxy will distribute traffic to. Each `server` directive specifies a server for HAProxy to route requests to. Note that `cplane-{0..2}` are arbitrary labels, what matters is `IP:port`. Last option in line is `check` which tells HAProxy to periodically confirm the health of the server. Requests are forwarder to other instances until server passes the heath check again.

### Control plane and worker nodes

Cplane and worker nodes are based on Ubuntu. We use version that is supported by kubespray. On these nodes, only prep to be done is to create `borg` user.

### Ansible part 1

For our use case we see few tasks at hand which we could do manually, and its fun and usually educational to do it like that for the first time. It's also fun to look for ways to optimize and go further into automation, hence we will use power of ansible.

Ansible is an open-source automation tool that provides a framework for defining and deploying system configuration across a wide range of environments. It uses yaml to define automation jobs. We are going to use this tool in very basic way ourselves, and later see how it is used by kubespray to automate cluster creation.

Make sure you have `ansible` installed. I run `ansible 2.9.6` with `python version = 3.8.10 (default, Nov 22 2023, 10:22:35) [GCC 9.4.0]` in WSL.  

The very tl;dr version on using ansible is:  
* set your inventory (so that ansible knows what machines to do work on)
* get your files in place (ie. `id_rsa.pub`, so that playbook can use its content)
* run your playbook
I encourage anyone to dig into ansible a bit, its very cool tool that lets you work on multiple servers at once, it also makes knowledge sharing among peers easier, and serves as executable documentation on how to set the system. Lets look at [ansible directory]({{ site.url-source }}/code/devops/ansible).

Before use, change `private_key_file = /path/to/your/.ssh/` line in `ansible.cfg` or pass that variable with `--private-key PRIVATE_KEY_FILE` flag.  

We can test our connection, and if config is ok with:
{% shell devops/ansible/ping ofrom=19 oto=24 %}

What you want to do is copy your `~/.ssh/id_rsa.pub` file here, and run setup ansible user playbook, so that every node is reachable from one service user, that has admin access, and can be ssh'ed into with your key.  

{% shell devops/ansible/user olines="42,51" %}

Next, run load balancer playbook to set up haproxy node. 

{% shell devops/ansible/load_balancer olines="21" %}

Now we have everything ready to run kubespray on top of our setup. 

## Spraying k8s cluster on top

Kubespray is an open-source project that provides Ansible playbooks for the deployment and management of Kubernetes clusters. 
Few things we are going to do are:
* get kubespray repo - `git clone https://github.com/kubernetes-sigs/kubespray.git`
* set yourself `virtualenv --python=$(which python3) kubespray-venv`, activate it
* install deps `pip install -U -r requirements.txt`

Now we copy and customize `inventory/sample` as per README from kubespray repo.  
There are some things we want to change before we spray.

in `mycluster/group_vars/all/all.yml` we change entries about load balancer and dns.
```yml
apiserver_loadbalancer_domain_name: "haproxy.k8s.local"
loadbalancer_apiserver:
  address: 10.0.10.200
  port: 8383

loadbalancer_apiserver_type: haproxy  # valid values "nginx" or "haproxy"

upstream_dns_servers:
  - 8.8.8.8
  - 8.8.4.4
```
In `mycluster/group_vars/k8s_cluster/k8s-cluster.yml` we change entries considering which network controller to use. 
```yml
kube_network_plugin: flannel
```

For me, other network plugins didn't work, and I have not yet dig into why.

In `mycluster/group_vars/k8s_cluster/addons.yml` for basic version of the system we can basically set everything to false. We will leave metrics turned on.

Our `inventory.ini` file has to match predefined labels that kubespray 

{% code devops/mycluster/inventory.ini lang=ini noshell=true noout=true %}

Now we can spray it!

{% shell devops/spray noout=true %}

In case of failure, it is safe to run `reset.yml` playbook, to redo the procedure.
{% shell devops/reset_spray noout=true %}

## Getting k8s credentials 
After kubespray finishes its job, you can use our primitive ansible playbook fetch conf to download `admin.conf` file that serves as credentials file for the cluster. 

{% shell devops/ansible/fetch_conf %}

So now we have our conf file ready in our system.
```bash
ls -al ./admin.conf 
-rw-r--r-- 1 killme killme 5673 Apr 17 13:56 ./admin.conf
```
Keep it somewhere where it wont get lost. File path to this file is exported in the shell as `KUBECONFIG` variable, and before using `kubectl` it needs to be set, for example with `export KUBECONFIG=/path/to/your/conf` so that kubernetes knows which cluster are we refering to when making api calls.

So after applying our export, we are able to do `kubectl get pods -A`. Depending on default addons turned on, there might be some pods spinning up already.

## Possible upgrades in the future

* [ ] Divide this article into two parts - infrastructure setup and spray.
* [ ] Write up how to set up DNS in your network
* [ ] Write up how to set up OS install over the network
* [ ] Write up procedure to set up infra on virtualbox
* [ ] Write Hyper-V set up in terraform, write up how to set up providers
* [ ] Compile terraform step into separate article
* [ ] Dig into spraying more, try out more options, turn on more addons