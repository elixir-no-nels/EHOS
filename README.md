# EHOS
**E**lastic **H**TCondor **O**penStack **S**caling - Pronounced EOS  
This script is for dynamic creation and deletion of OpenStack virtual machines that run HTCondor execute nodes. It is intended for a scenario where you 
want to run a compute cluster with a low overhead when the usage is low, and you want to be able to dynamically scale up and scale down your cluster as 
the usage increases or decreases. There currently is support for similar functionality in HTCondor, called `condor_annex`, but it only works with amazon. 
It seems like there will be OpenStack support in future releases which will render this script obsolete. There's also the HTCondor grid universe for 
OpenStack, but it has no dynamic scaling. Many others have built various methods to dynamically scale an HTCondor cluster, but this implementation differs 
in that it is very simple and has no dependencies. 

## Dependencies  
This has been developed on Centos7 on an OpenStack cloud running version 3.15.0, and HTCondor version 8.7.8.

## Installation and setup  
First you need to enter your OpenStack login credentials into a keyston_rc.sh file and source it so the `openstack` command can run properly. 
Then clone this repository `git clone https://github.com/elixir-no-nels/EHOS` and run `./DynamicVM-DynamicScaling-0.2.sh` and it's running with the base 
configuration settings. You probably want to change them.

## Usage  
Assuming you've already created a VM image with a preconfigured HTCondor execute node installed, and created an SSH key for it, you're good to go to start 
editing the configuration.sh file to suit your setup. The configuration file is read every time the while loops repeats, so on the fly configuration is 
possible.
The comments in the configuration.sh file should be enough to explain what the variables are used for.

## Bugs  
It does not always report the correct number of available threads, it seems to occur when mixed flavors are running.
