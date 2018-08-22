#!/bin/bash

## Uncomment for CLI debugging
set -o xtrace
set -v

#exec >logfile 2>&1
exec > >(tee logfile) 2>&1

## while loop
while
	true
	## Display date
	date

	## Read configuration file
#	source $(pwd)/configuration.sh
	source $(pwd)/variablecreation.sh

## Beginning of variable creation and main loop
do
	## Delete idle nodes that are not needed
#	if [[ "${#IDLENODES[@]}" -ge "${#BUSYMACHINES[@]}" && "${#IDLENODES[@]}" -gt "$MINNODES" ]] 2>>logfile; then
	if [[ "${#IDLENODES[@]}" -ge "$MINNODES" && "${#IDLENODES[@]}" -gt "$REDUNDANTNODES" ]] 2>>logfile; then
		echo "Deleting idle node "$MACHINETOKILL""
		condor_off -fast -name $MACHINETOKILL.novalocal
		openstack server delete $MACHINETOKILL
		date
		sleep $SHORTSLEEP

	## Do nothing if max number of execute nodes has been reached
	elif [[ "${#EXECUTENODES[@]}" -eq "$MAXNODES" ]] 2>>logfile; then
		echo "Max execute node limit has been reached"
		date
		sleep $SHORTSLEEP

	## Create execute node if none are running
	elif [[ "${#EXECUTENODES[@]}" -lt "$MINNODES" && "${#EXECUTENODES[@]}" -le "$MAXNODES" ]] 2>>logfile; then
		VM=$(date +%s)
			echo "All execute nodes are full, or the minimum number of machines is not running, create command will execute"
			./createvm.sh $SMALL 2>&1>>logfile
			echo "Create command for "$CONDORINSTANCENAME"-"${VM}" sent"
			date
			sleep $LONGSLEEP

		## Create execute node if there are idle jobs and the max vm quota is not exceeded
	elif [[ "$IDLEJOBS" -gt 0 && "${#EXECUTENODES[@]}" -le "$MAXNODES" ]] 2>>logfile; then if [[ "$REQCPUS" -ge 1 ]] || [[ "$IDLEJOBS" -gt "$IDLEJOBVMC" ]] 2>>logfile; then
#		while [[ "${#EXECUTENODES[@]}" -lt "$MAXNODES" ]]; do
			VM=$(date +%s)
			echo "There are idle jobs, sending create command for "$CONDORINSTANCENAME"-"${VM}""
			./createvm.sh $LARGE 2>&1>>logfile
			echo "Sleeping for $LONGSLEEP seconds"
			sleep $LONGSLEEP
			echo "Create command for "$CONDORINSTANCENAME"-"${VM}" sent"
			source $(pwd)/variablecreation.sh
#		done
		date
		sleep $LONGSLEEP
	else
		VM=$(date +%s)
			echo "There are idle jobs, sending create command for "$CONDORINSTANCENAME"-"${VM}""
			./createvm.sh $SMALL 2>&1>>logfile
			echo "Create command for "$CONDORINSTANCENAME"-"${VM}" sent"
			date
			sleep $LONGSLEEP
	fi
	## Create one redundant execute node if all currently running execute nodes are full
	elif [[ "$IDLEJOBS" -eq 0 && "$RUNNINGJOBS" -gt 1 && "$RUNNINGJOBS" -eq "$MAXJOBS" && ${#EXECUTENODES[@]} -le "$MAXNODES" ]] 2>>logfile; then
		VM=$(date +%s)
			echo "Redundant node is needed, sending create command for "$CONDORINSTANCENAME"-"${VM}""
			for i in $(seq 1 $REDUNDANTNODES); do
				./createvm.sh $SMALL 2>&1>>logfile && sleep 1;
			done
			echo "Create command for "$CONDORINSTANCENAME"-"${VM}" sent"
			date
			sleep $LONGSLEEP

		## Do nothing if minimum node limit has been reached
	elif [[ "${#EXECUTENODES[@]}" -eq "$MINNODES" ]] 2>>logfile; then
		echo "The minimum number of execute nodes are running, do nothing."
	fi

	# Sometimes OpenStack creates an instance where the Network information in `openstack server list` is in reverse order
	# Meaning the IPv6 IP comes before the IPv4 IP, and that breaks the kill redundant node function
	# These faulty formated instances are deleted immediately since the bug is on the OpenStack side
	# No clean solution can be implemented as of now, this workaround has to do
	if [ ! -z "$IPV6MACHINETOKILL" ] 2>>logfile; then
		openstack server delete "$IPV6MACHINETOKILL"
		echo "Instance with IPv6 where IPv4 IP should be has been created, killing $IPV6MACHINETOKILL"
	elif [ -z "$IPV6MACHINETOKILL" ] 2>>logfile; then
		echo "No instance with IPv6 where IPv4 IP should be has been created, it's all good."
	fi
	echo "Nothing is happening, sleeping for 60 seconds"
		sleep $LONGSLEEP
		clear
done
