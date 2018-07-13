# EHOS
**E**lastic **H**TCondor **O**penStack **S**caling - Pronounced EOS  
This script is for dynamic creation and deletion of OpenStack virtual machines that run HTCondor execute nodes. It is intended for a scenario where you want to run a compute cluster with a low overhead when the usage is low, and you want to be able to dynamically scale up and scale down your cluster as the usage increases or decreases. There currently is support for similar functionality in HTCondor, called `condor_annex`, but it only works with amazon. It seems like there will be OpenStack support in future releases which will render this script obsolete. There's also the HTCondor grid universe for OpenStack, but it has no dynamic scaling. Many others have built various methods to dynamically scale an HTCondor cluster, but this implementation differs in that it is very simple and has no major dependencies that need special configuration.

## Dependencies
This has been developed on Centos7 with python-openstackclient version 3.15.0 and HTCondor version 8.7.8.

# Installation and setup
To use the OpenStack CLI you need to run `sudo pip install python-openstackclient`.
These instructions assume you're familiar with OpenStack and HTCondor, or you should be an adventurous person because there are manual steps that require basic understanding of how to use a command line. You must manually edit each command with your specific cloud details, prefered image names etc, don't just copy/paste and assume it'll work because it won't.  
Doing it all on the web interface is impossible, so if you're not familiar with manual creation of virtual machines with the OpenStack CLI, this is a good time to get familiar with that. If you're a UH-IaaS user, here's a link to the documentation: http://docs.uh-iaas.no/en/latest/  
And you might also want to keep the HTCondor documentation website open in case you want to research something: http://research.cs.wisc.edu/htcondor/manual/  
A tip is to use the search function because the documentation can be a bit hard to navigate at times.
Now that we have that out of the way, the first thing to do is to enter your OpenStack login credentials into a `keystone_rc.sh` file, you can use the one in this repository as a sample file, ask your admin where to find the information for the `keystone_rc.sh` file. When you have filled in all details correctly, run `source keystone_rc.sh` and then `openstack server list` to verify that it works.  

## Creating the base image
To build the base HTCondor image you can use the the `vanilla-condor.sh` script, edit it according to your base image needs, you might not want everything that gets installed, and might want to install things aren't installed. When the config file has been edited, use the following code as a template, edit it with you specific details and hit enter when you're done:  
`openstack server create --flavor a.flavor --image ACentOS7Image --nic net-id=aNetID --security-group ASecurityGroup --key-name your-ssh-key --user-data vanilla-condor.sh HTCondorBaseImage`
Once it has been built you need to make a snapshot of it, to do that you need the image ID, to find that, run `openstack server list`, copy the ID for your HTCondorBaseImage and paste it into the following command: `openstack image create --id A-Long-ID-With-Letters-And-Numbers NameOfBackedUpImage`  
Now that you have a snapshot of the base image you can use that to create an HTCondor master node and an HTCondor execute node.  

## Creating the master node and configuring EHOS
The master node needs manual configuration when it has been created, but before you create it, edit the `master-config.yaml` and change the variables with correct IP numbers etc. In case you want to add a line, make sure to use space instead of tab to create the indentation, otherwise it won't work when you run the create command later.  
Once you're done editing run the following command to create the master node:  
`openstack server create --flavor a.flavor --image NameOfBackedUpImage --nic net-id=ASecurityGroup --key-name your-ssh-key --user-data master-config.yaml HTCondorMaster`  
Once it has been created you must SSH into it and open `/etc/condor/condor_config` and set `CONDOR_HOST =` to your htcondor master node IP.
When you're done editing, save and exit and then run `condor_reconfig` to load the new config file.  

## Creating the execute node
Two files must be edited, first open the `execute-config.yaml` and change `CONDOR_HOST =` to the address of your master node, then go through each line to see what else needs to change for your setup to work. If this is completely new to you, it's time to learn on your own because you need to know this. Once you're done with the yaml file you need to edit `configuration.sh` and edit each line according to your local requirements and preferences. Each line should be sufficiently explained by the comments. Assuming that the `configuration.sh` file is correctly edited we can let the main EHOS script do the rest for us. If you have gone through each point in the configuration file and verified that every detail is correct, the `DynamicVM-DynamicScaling-*.sh` script will take care of creating and deleting execute nodes for you. But if you want to troubleshoot things manually, use this line to verify that you can create an execute node yourself:  
`openstack server create --flavor m1.large --image NameOfBackedUpImage --nic net-id=dualStack --security-group default --key-name your-ssh-key --user-data execute-config.yaml HTCondorManuallyCreatedExecuteNode`

That should be it, just run `./DynamicVM-DynamicScaling-0.2.2.sh`, sit back and watch it do its magic.

## Good things to know
The `configuration.sh` file is read every time the loop in the main script runs again, so you can do on the fly changes to the script. The same is true for the `createvm.sh` script, every time it runs it reads the `configuration.sh` file, so you don't need to restart the main script for changes to take effect.  
If you want a logfile you can run `./DynamicVM-DynamicScaling-0.2.2.sh 2>&1>>logfile` to capture relevant events to the logfile. This is the preferred mode of execution since you will get information about what has happened in case you need to troubleshoot or something.  
You can use the `createvm.sh` script to manually create a VM too, just run `./createvm.sh m1.large` and make sure that the `configuration.sh` file has the correct settings for the VM you want to create. 

## Bugs
If the available resource quota is (almost) full the script will still try to create a new VM if it hasn't hit the max number of nodes quota yet. I have tried to find a way to first check the available resource quota to avoid this behavior, but it doesn't seem possible with UH-IaaS, so it will keep needlessly "bumping its head into the wall" unless I make a function that requires the user to fill in the size of each flavor (like m1.large is 2 cores, 8GB RAM, m1.xlarge is 4 cores, 16GB RAM etc) as well as the available quota (number of cores, RAM, instances etc) and then add the running flavors together to calculate how much of the quota has been used. I want to keep the setup process simple though, so it might be better to keep it stupid to preserve simplicity of setup. If you want every feature under the sun and a polished surface you should check out Cloud Scheduler: https://github.com/hep-gc/cloud-scheduler It has everything you need, including a complicated setup and a ton of useful features. 
