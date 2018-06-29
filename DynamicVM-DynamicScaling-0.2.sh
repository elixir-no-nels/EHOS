#!/bin/bash

## Uncomment for CLI debugging
set -o xtrace

## while loop
while true
	## Display date
	date

	## Set variables for maximum and minimum number of nodes
	MAXNODES=8
	MINNODES=4

	## Beginning of variable creation and main loop
	do
	## Count the number of idle jobs
	IDLEJOBS=$(condor_q -l -submitter galaxy -submitter centos | grep -wc 'JobStatus = 1')
	echo "The number of idle jobs is $IDLEJOBS"

	## Count how many slots are available to calculate max jobs/slots
	MAXJOBS=$(condor_status -l | grep -i "TotalSlotCpus = [2,4,8]" | awk 'BEGIN{ total=0 } { total=total+$3} END{ printf total }')
	echo "The execute node(s) can currently run "$MAXJOBS" jobs/threads"

	## Count how many jobs are currently running
	RUNNINGJOBS=$(condor_q -l -submitter galaxy -submitter centos | grep -wc 'JobStatus = 2')
	echo "The number of running jobs is $RUNNINGJOBS"
	let RUNNINGJOBSPLUS1=RUNNINGJOBS+1

	## Create array with IP numbers of idle nodes
	readarray IDLENODES < <(condor_status -l | grep -iEo 'StartdIpAddr = "<[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | uniq -u | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
	echo "The number of idle execute nodes is ${#IDLENODES[@]} and the idle node IP(s) is
	${IDLENODES[@]}"

	## Create array with IP numbers of nodes that are running jobs
	readarray BUSYMACHINES < <(condor_q -l -submitter centos | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u)
	echo "The following execute nodes are running jobs 
	${BUSYMACHINES[@]}"
	let BUSYMACHINESPLUS1=${#BUSYMACHINES[@]}+1

	## Create array with name and IP address information of the execute nodes that have been created on openstack
	readarray EXECUTENODES < <(openstack server list --name htcondorexecute -c Name -c Networks -c Status -f value)
	echo "Total number of execute nodes in the pool is: 
	${#EXECUTENODES[@]}
	and the name(s) of the running node(s) is
	${EXECUTENODES[@]}"

	## Variable that chooses which node to kill based on the conditionals below
	MACHINETOKILL=$(echo ${EXECUTENODES[@]} | grep -Eo "htcondorexecute-[0-9]* ACTIVE dualStack=${IDLENODES[0]}" | awk {' print $1'})
	echo "\$MACHINETOKILL is $MACHINETOKILL"

	## Display information about how many jobs are idle and how many execute nodes are available
	echo "$IDLEJOBS jobs are idle and there's ${#EXECUTENODES[@]} execute node(s) available"

	## Display all conditionals for better debugging
	echo "Create execute node if none are running, or if all execute nodes are busy conditional equals: [[ "${#IDLENODES[@]}" -eq 0 && "${#EXECUTENODES[@]}" -le "$MAXNODES" ]]"

	echo "Max node count conditional equals: [[ "${#EXECUTENODES[@]}" -eq "$MAXNODES" ]]"

	echo "Minimum node count conditional equals: [[ "${#EXECUTENODES[@]}" -eq "$MINNODES" ]]"

	echo "Execute node creation conditional equals: [[ "$IDLEJOBS" -gt 0 && "${#EXECUTENODES[@]}" -le "$MAXNODES" ]]"

	echo "Redundant node creation conditional equals: [[ "$IDLEJOBS" -eq 0 && "$RUNNINGJOBS" -gt 1 && "$RUNNINGJOBS" -eq "$MAXJOBS" && ${#EXECUTENODES[@]} -le "$MAXNODES" ]]"

	echo "Idle node deletion conditional equals: [[ "${#IDLENODES[@]}" -ge "${#BUSYMACHINES[@]}" && "${#IDLENODES[@]}" -ge "$MINNODES" ]]"

	## Delete idle nodes that are not needed
	if [[ "${#IDLENODES[@]}" -ge "${#BUSYMACHINES[@]}" && "${#IDLENODES[@]}" -gt "$MINNODES" ]]
		then echo "Deleting idle node" && \
		echo "$MACHINETOKILL" && \
		condor_off -fast -name $MACHINETOKILL.novalocal && \
		openstack server delete $MACHINETOKILL && \
		date && sleep 15

	## Do nothing if max number of execute nodes has been reached
	elif [[ "${#EXECUTENODES[@]}" -eq "$MAXNODES" ]]
		then echo "Max execute node limit has been reached" && \
		date && sleep 15

	## Create execute node if none are running
	elif [[ "${#EXECUTENODES[@]}" -lt "$MINNODES" && "${#EXECUTENODES[@]}" -le "$MAXNODES" ]]
		then VM=$(date +%s) && \
		echo "All execute nodes are full, or the minimum number of machines is not running, create command will execute" && \
		openstack server create --flavor m1.large --image HTCondorExecute-18-06-18 --nic net-id=dualStack \
		--security-group Pipeline-development --security-group test --security-group default --key-name vgcn-testing htcondorexecute-"${VM}" && \
		echo "Create command for htcondorexecute-"${VM}" sent" && date && sleep 60

	## Create execute node if there are idle jobs and the max vm quota is not exceeded
	elif [[ "$IDLEJOBS" -gt 0 && "${#EXECUTENODES[@]}" -le "$MAXNODES" ]]
		then if [ "$IDLEJOBS" -gt 40 ]
			then VM=$(date +%s) && \
			echo "There are idle jobs, sending create command for HTCondorExecute-"${VM}"" && \
			openstack server create --flavor m1.xlarge --image HTCondorExecute-18-06-18 --nic net-id=dualStack \
			--security-group Pipeline-development --security-group test --security-group default --key-name vgcn-testing htcondorexecute-"${VM}" && \
			echo "Create command for htcondorexecute-"${VM}" sent" && date && sleep 60
			else
			VM=$(date +%s) && \
			echo "There are idle jobs, sending create command for HTCondorExecute-"${VM}"" && \
			openstack server create --flavor m1.large --image HTCondorExecute-18-06-18 --nic net-id=dualStack \
			--security-group Pipeline-development --security-group test --security-group default --key-name vgcn-testing htcondorexecute-"${VM}" && \
			echo "Create command for htcondorexecute-"${VM}" sent" && date && sleep 60
		fi
	## Create one redundant execute node if all currently running execute nodes are full
	elif [[ "$IDLEJOBS" -eq 0 && "$RUNNINGJOBS" -gt 1 && "$RUNNINGJOBS" -eq "$MAXJOBS" && ${#EXECUTENODES[@]} -le "$MAXNODES" ]]
		then VM=$(date +%s) && \
		echo "Redundant node is needed, sending create command for htcondorexecute-"${VM}"" && \
		openstack server create --flavor m1.large --image HTCondorExecute-18-06-18 --nic net-id=dualStack \
		--security-group Pipeline-development --security-group test --security-group default --key-name vgcn-testing htcondorexecute-"${VM}" && \
		echo "Create command for htcondorexecute-"${VM}" sent" && date && sleep 60

	## Do nothing if minimum node limit has been reached
	elif [[ "${#EXECUTENODES[@]}" -eq "$MINNODES" ]]
		then echo "The minimum number of execute nodes are running, do nothing."
	fi

## Display information for debugging again
echo "____________________________"
echo "\$MACHINETOKILL is $MACHINETOKILL"

echo "$IDLEJOBS jobs are idle and there's ${#EXECUTENODES[@]} execute node(s) available"

echo "Total number of execute nodes in the pool is: 
${#EXECUTENODES[@]}
and the name(s) of the running node(s) is
${EXECUTENODES[@]}"

echo "The following execute nodes are running jobs 
${BUSYMACHINES[@]}"

echo "The number of idle execute nodes is ${#IDLENODES[@]} and the idle node IP(s) is 
${IDLENODES[@]}"

echo "The number of running jobs is $RUNNINGJOBS"

echo "The execute node(s) can currently run "$MAXJOBS" jobs/threads"

echo "The number of idle jobs is $IDLEJOBS"

echo "Nothing is happening, sleeping for 60 seconds" && sleep 60 && clear
done
