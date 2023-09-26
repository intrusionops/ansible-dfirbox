# Setup a DFIR investigation box with Ansible
### What is this
This is an ansible playbook that will modify a default Debian 12 installation and prepare it to be used for a forensic analysis workstation.

Forensics is risky work so workstations should be reinstalled often, whether between every case, or monthly. Treat it as untrusted.
Ideally your forensic box wouldn't be connected to the Internet, but that's simply not practical outside of law enforcement/federales.

The practical precautions we can take are to closely monitoring system activity (remotely), reinstalling often, jailing processes where possible, using network isolation, and OS hardening.

You may have cases that require the data reside in Europe or Asia. You can spin up a cloud VM and run this ansible playbook to have the same tools, hardening, and ascetics as your trusty physical server that's locked in your server room.

### Assumptions
- You've already installed Debian 12. It may work on other versions of Debian but I've only tested on 12
- You've already handled disk volumes. You'll want a few drives to be optimally effective. One for the OS, a larger disk that's slower for 
  larger storage, and a fast medium sized disk to speed up intensive ingest jobs. You should already have these configured and mounted 
  outside of this playbook. Those volumes aren't referenced anywhere
- You've already handled disk encryption. Your root drive should be encrypted at installation time, and any data or cache volumes 
  should be encrypted when you create them. I recommend using LUKS
- Linux is your primary investigation platform. There are some tasks, like mobile forensics or some ungodly keyfob, where you'll likely want a Windows VM. This 
  playbook prepares kvm and qemu so you can setup and run Windows VMs and pass thru hardware as needed
- You use tailscale for VPN. If you don't, comment out the line with artis3n.tailscale in ```playbook.yml```

### What does it do
For anyone unfamiliar, ansible is a framework that lets you write simple yaml files that define what your OS configuration should look like.
You don't need to know ansible to use this and I'll assume not every reader is an ansible pro because I'm certainly not. 

This ansible playbook performs the following tasks:
 - Runs OS updates
 - Installs multiple tools from apt that I use often. These include general Linux utilities and forensic specific tools and packages.
   You can see the full list in ```roles/system/tasks/main.yml``` and ```roles/dfir/tasks/main.yml```. 
 - Disables OS hiberation/suspend
 - Sets up sudo
 - Installs and configures ```osquery``` for security monitoring. This causes all process creation, file and network activity to be logged
   to a JSON file. You should ship this JSON data elsewhere in real time to a SIEM but that's outside the scope of this playbook.
   osquery gives us the same telemetry as EDR without the performance impact or voluntarily sharing all your data with multiple intelligence agencies
 - Uses devsec playbooks to implement OS and SSH hardening
 - Installs and configures ```docker```
 - Sets up ```lxc``` so you can run forensic jobs in jails rather than your host OS
 - Sets up ```kvm```, ```libvirt```, and ```qemu``` so you can run other VMs such as Windows for tasks that demand it
 - Adds some GUI tools like VSCodium (de-microsofted VSCode), Brave Browser (built-in tor browsing), thunderbird, and chromium (de-googled Chrome)
 - Modifies desktop launchers for the apps above, and libreoffice, so they launch with ```firejail```
 - Installs multiple forensic tools from the debian package manager. Note, we do not use the debian metapackages for forensics-all 
   and forensics-extra because some packages conflict with others needed later. We hand select most of the individual packages
 - Sets up ```croc```. If you haven't used croc, seriously, check it out. Cross platform, fast, encrypted file transfer using mnemonic and 
   supports download resume. You can self-host croc on a static IP and have clients share images this way. It works great
 - Sets up ```syncthing``` and ```mdcat```. Self-hosted syncthing is great for sharing things like case notes between trusted computers, and mdcat 
   is a cli that lets you read markdown
 - Installs ```awscli```. awscli supports multi-part upload and download and is a common way customers are willing to share large evidence stashes
 - Installs and configures ```volatility```
 - Grabs misc projects like ```ForensicArtifacts```, ```sigma```, Neo23x0 yara rules, ```chainsaw```, ```hayabusa```, ```oletools```
 - Create /opt/tools/dist with files we may need to share with clients for evidence collection
 - Pulls the docker container for log2timeline/plaso
 - Pulls the docker container for ipeddocker/iped (thx Brazil)
 - Grabs the ```timesketch``` installer so you can easily docker-compose to bring up/down stacks per investigation
 - Installs, configures, and tweaks ```autopsy``` and ```sleuthtoolkit```. A UI shortcut is created. autopsy and ```solr``` have configurable memory and thread 
   settings that help you get improved performance
 - Downloads common autopsy plugins and Python modules 
 - Installs ```rclone``` another common tool used to download or exfiltrate large volumes of data to multiple cloud providers
 - Adds a system user, sets up their SSH key, and adds them to the sudo and docker groups
 - Sets up ```borgbackup``` that you can configure for encrypted, de-duplicated backups to external drives or cloud storage.

# Using this playbook
Carefully review ```group_vars/all/host_vars.yml``` and adjust as desired.

Review ```playbook.yml``` and comment out any portions you don't want applied.


### Install roles from galaxy
Run this on the machine you'll execute ansible from. 

```
$ ansible-galaxy collection install devsec.hardening
$ ansible-galaxy install stefangweichinger.ansible_rclone
$ ansible-galaxy install artis3n.tailscale
```


### Run playbook

```
$ TAILSCALE_KEY="tskey-xxxxx" ansible-playbook -i inventory/hosts playbook.yml
```

It's unnecessary to pass the ```TAILSCALE_KEY``` environment variable if you're not using tailscale and have commented it out in playbook.yml.

Your DFIR rig should be ready for you to start work on a case after the playbook completes. I use ```ssh -X``` to access the box headless and then launch autopsy over an X SSH tunnel, but this has also been tested directly from the server console.

# Troubleshooting
If you get an error from the tailscale role it may be because your tailscale network is configured to require host authorization. This is 
a good thing. The playbook should continue and you can login to https://login.tailscale.com/admin/machines to authorize the endpoint.

Don't run the tailscale playbook twice or you may get errors I didn't spend time troubleshooting. Simply comment it out after the first execution.


# TODO
Some things I'll probably never get around to doing but could be useful:
 - Test with https://www.kicksecure.com/wiki/Main_Page
 - Use ansible to provision a Windows VM via kvm then use vagrant to automate setting up common forensic tools on Windows
 - Postfix config to relay with your mail provider of choice so you can get cron and misc job notifications
 - Yubikey setup

 # Credits
 The autopsy role is based off https://github.com/jgru/ansible-forensic-workstation/blob/master/roles/autopsy/tasks/main.yml 
 but has modifications. Thanks jgru.

 An unnamed Canadian friend who likes writing ansible. 