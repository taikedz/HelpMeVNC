#!/bin/bash

echo "======"
date # for the log

matcher='^[0-9]+$'
tport=$1
tserver=$2

if [[ $(ps x | grep fNC | grep -v grep | wc -l) -gt 0 ]]; then
	echo "There's already a reverse tunnel active"
	echo $(ps aux | grep fNC | grep -v grep)
	exit
fi

if [[ $tport =~ $matcher ]]; then

sport=$(($tport+1))

ssh -fNC -R $1:localhost:22 $tserver -o ServerAliveInterval=60 
[[ "$?" -lt 1 ]] && cat <<EOF

    A reverse tunnel has been opened to port ---$tport--- on $tserver

Connect a new session to this tunnel direct from your PC
	ssh $tserver

When logged in to $tserver, ssh to the local host on the port you specified
	ssh -p $1 localhost


To make this machine available directly to clients of $tserver on port $sport,
log in to $tserver and run:

	ssh -L$sport:localhost:$tport -g -o TCPKeepAlive=yes -t 127.0.0.1 screen

Leave the session running until it is no longer needed.

!!!!! Remember to kill this tunnel when you are finished !!!!

	kill $(echo "localhost:22 $tserver" | sed -r -e 's/^\s*([0-9]+).+$/\1/')


EOF
else
cat <<EOF
Please provide a port and server for the tunnel to connect to.

Example:

	$0 PORT SERVER

Current reverse tunnels:

$(ps x | grep fNC | grep -v grep)

=======/
EOF
fi
