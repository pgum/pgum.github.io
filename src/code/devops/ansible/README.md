# Ansible for infra

This is super basic example of how to do some automation so we don't have to set up nodes manually.  

Before use, change `private_key_file = /path/to/your/.ssh/` line in `ansible.cfg` or pass that variable with `--private-key PRIVATE_KEY_FILE` flag.  

What you want to do is copy your `~/.ssh/id_rsa.pub` file here, and run setup ansible user playbook, so that every node is reachable from one service user, that has admin access, and can be ssh'ed into with your key.  

Next, run load balancer playbook to set up haproxy node. 

After doing that, you can use kubespray to get a running cluser on your nodes. After it finishes its job, you can use fetch conf playbook to download `admin.conf` file that serves as credentials file for the cluster.  

```bash
ansible-playbook ping.yaml --user=killme

....

PLAY RECAP *************************************************************************************************************************************cplane-0.k8s.local         : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
cplane-1.k8s.local         : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
cplane-2.k8s.local         : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
haproxy.k8s.local          : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
worker-0.k8s.local         : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
worker-1.k8s.local         : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

So that we know that we can connect to nodes. Now we create `borg` user on all nodes.
```bash
ansible-playbook setup_ansible_user.yaml --user=killme

....

PLAY RECAP *************************************************************************************************************************************cplane-0.k8s.local         : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
cplane-1.k8s.local         : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
cplane-2.k8s.local         : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
haproxy.k8s.local          : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
worker-0.k8s.local         : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
worker-1.k8s.local         : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

With use of `load_balancer.yaml` we setup haproxy node and copy configuration file over to serve our needs.
```bash
ansible-playbook load_balancer.yaml

PLAY RECAP *************************************************************************************************************************************haproxy.k8s.local          : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
