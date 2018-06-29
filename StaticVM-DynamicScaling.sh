#!/bin/bash

while true
	date
	do IDLEJOBS=$(condor_q -l -submitter galaxy -submitter centos | grep -wc 'JobStatus = 1')
	echo "The number of idle jobs is $IDLEJOBS"

	RUNNINGJOBS=$(condor_q -l -submitter galaxy -submitter centos | grep -wc 'JobStatus = 2')
	echo "The number of running jobs is $RUNNINGJOBS"
	let RUNNINGJOBSPLUS1=RUNNINGJOBS+1

	readarray IDLENODES < <(condor_status -l | grep -iEo 'StartdIpAddr = "<[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | uniq -u | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
	echo "The number of idle nodes is ${#IDLENODES[@]} and the idle nodes are
	${IDLENODES[@]}"

	readarray BUSYMACHINES < <(condor_q -l -submitter centos | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | sort -u)
	echo "The following execute nodes are running jobs 
	${BUSYMACHINES[@]}"

	readarray EXECUTENODES < <(openstack server list --name HTCondorExecute -c Name -c Networks -c Status -f value)
	echo "Total number of execute nodes in the pool is: 
	${#EXECUTENODES[@]}"

	readarray MACHINENAMES < <(echo ${EXECUTENODES[@]} | grep -o "HTCondorExecute[0-9] SHUTOFF" | grep -o HTCondorExecute[0-9])
	echo "Name(s) of shut down execute nodes(s): 
	${MACHINENAMES[@]}"

	readarray MACHINEIPS < <(echo ${EXECUTENODES[@]} | grep -Eo "ACTIVE dualStack=[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -oE "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
	echo "IP numbers of running execute nodes: 
	${MACHINEIPS[@]}"

	MACHINESTOKILL=$(echo ${EXECUTENODES[@]} | grep ${IDLENODES[0]} | awk {' print $1'})

	echo "$IDLEJOBS jobs are idle and there's ${#MACHINENAMES[@]} execute node(s) available"

	if [[ "$IDLEJOBS" -gt 0 && "${#MACHINENAMES[@]}" -eq 0 ]]
		then echo "All execute nodes have been started" && \
		date && sleep 15 && clear
	elif [[ "$IDLEJOBS" -gt 0 && "${#MACHINENAMES[@]}" -gt 0 ]]
		then echo "Sending start command for ${MACHINENAMES[0]}" && \
		openstack server start ${MACHINENAMES[0]} && echo "Start command for ${MACHINENAMES[0]} sent" && date && sleep 15 && clear
	elif [[ "$RUNNINGJOBS" -eq "${#MACHINEIPS[@]}" && ${#MACHINENAMES[@]} -gt 0 ]]
		then echo "Starting one redundant execute node" && \
		openstack server start ${MACHINENAMES[0]} && echo "Start command sent to ${MACHINENAMES[0]}" && date && sleep 15 && clear
	elif [[ "$RUNNINGJOBS" -lt "${#MACHINEIPS[@]}" && "${#MACHINEIPS[@]}" -gt "$RUNNINGJOBSPLUS1" ]]
		then echo "Killing idle node" && \
		echo "$(openstack server list -c Networks -c Name -f value | grep ${IDLENODES[0]} | awk {' print $1 '})" && \
		openstack server stop $(openstack server list -c Networks -c Name -f value | grep ${IDLENODES[0]} | awk {' print $1'}) && \
		date && sleep 15 && clear
	fi

echo "Nothing is happening, sleeping for 60 seconds" && sleep 60 && clear
done

#BUSYMACHINES

	RJE=0
	let RJE+=RUNNINGJOBS+1
