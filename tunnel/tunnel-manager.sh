#! /bin/bash

# Script to automatically start or kill a tunnel
# Saves information to a ~/.config/helpmesee/tunnels/PORT.pid containing the PID of the SSH instance

# TODO : extra features to include
# STATUSALL - display the statuses of all tunnels
# A GUI ...!

# Declare global variables

t_confdir=$HOME/.config/helpmesee/tunnels # FIXME - need to put this in a shared space - /usr/local/share ?
mkdir -p $t_confdir
if [[ $? != 0 ]]; then
	echo "Could not make preferences directory!"
	exit 1
fi

OSTYPE=$(uname -s)
SEDC='sed -r'
PSC="ps ux $UID"
case $OSTYPE in
	Darwin)
		SEDC='sed -E'
		PSC="ps -u $UID -x"
		;;
esac


# DECLARE ARGS

t_action=
t_lport=
t_rport=
t_rserv=
t_ruser=
t_cport=


for var in "$@"; do
	if [[ $var =~ "^--help|-h|/h$" ]]; then
		cat <<EOHELP
Remote Tunnel Manager

$0 - Open a remote tunnel

Assuming you can tunnel to a remote server, this script is intended to take care of the logic of testing and managing a remote tunnel connection

== Usage ==

Full set of arguments

	$0 --lport=LPORT {STATUS|STOP}
	$0 --ssh=USER@SERVER[:CPORT] --tunnel=RPORT-LPORT {START|STOP|STATUS}

Connection details:

SERVER
	The remote server which is the front end of the tunnel

USER
	The user on the remote server

CPORT
	The SSH port of the remote server

Tunnel details:

RPORT
	The port on the remote server which is listening

LPORT
	The local port you want to forward the tunnel to

EOHELP
		exit 0
	fi

	#echo "Processing [$var]"

	matcher="^(START|STOP|STATUS|LIST)$"
	[[ $var =~ $matcher ]] && t_action=${BASH_REMATCH[1]}

	matcher="^--tunnel=([1-9][0-9]+)-([1-9][0-9]+)$"
	[[ $var =~ $matcher ]] && {
		t_rport=${BASH_REMATCH[1]}
		t_lport=${BASH_REMATCH[2]}
	}

	matcher="^--lport=([1-9][0-9]+)$"
	[[ $var =~ $matcher ]] && { t_lport=${BASH_REMATCH[1]}; }

	matcher="^--ssh=([a-zA-Z0-9_-]+)@([^.][a-z0-9\\.-]+[^.])(:([1-9][0-9]+))?$"
	[[ $var =~ $matcher ]] && {
		# An old man in a care home is complaining about the eggs:
		# "They taste of nothing. Nothing. Just nothing."
		# To which the nurse replies, "I just cook the eggs - I don't lay them."

		t_ruser=${BASH_REMATCH[1]}
		t_rserv=${BASH_REMATCH[2]}
		t_cport=${BASH_REMATCH[4]}
		[[ -z $t_cport ]] && { t_cport=22; }
	}
	
	matcher="^--i=(.+)$"
	[[ $var =~ $matcher ]] && {
		t_iden="$HOME/.ssh/"${BASH_REMATCH[1]}
		[[ ! -f "$HOME/.ssh/$t_iden" ]] && {
			pemid="$t_iden.pem"
			[[ ! -f "$pemid" ]] && {
				echo "Identity file '$t_iden' or '$pemid' not found."
				exit 2
			}
			t_iden="$pemid"
		}
		t_iden="-i $t_iden"
	}

	matcher="^-v|--verbose$"
	[[ $var =~ $matcher ]] && t_verbose=yes
done

# ===
# Argument processing is done
# ================================

if [[ "x$t_verbose" == "xyes" ]]; then

cat <<EOF
Action: $t_action

Local port: $t_lport
Remote port: $t_rport

Server: $t_rserv
Remote user: $t_ruser
Connection port: $t_cport
Identity file: $t_iden
---------------------------------------
EOF

fi

# ============
# Need to be able to find connections we did not initiate
# Would be nice to be able to manage tunnels by name

# TODO - do variables check
# on fail checking, run "$0 --help" and exit

CONNALIVE="-o ServerAliveInterval=20 -o ServerAliveCountMax=5"

case $t_action in
START)
	if [[ ! -f "$t_confdir/$t_lport.log" ]]; then
		# TODO - during initial setup, keys should be created
		# Method for managing/sending ID would be useful...
		set -e
		CONNSTR="$t_rport:localhost:$t_lport $t_ruser@$t_rserv"
		ssh -fNC -R $CONNSTR -p $t_cport $t_iden $CONNALIVE 
		pidline=$( $PSC | grep "$CONNSTR" | grep -v grep )
		# extract PID
		pid=$( echo $pidline | $SEDC "s#^\\s*($USER|$UID)\\s+([0-9]+)\\s+.+\$#\2#" ) # should work now...
		echo -e "$pid\n$pidline" > "$t_confdir/$t_lport.log"
		set +e
	else
                echo -n "There is a tunnel running for port $t_lport: "
                tail -n 1 "$t_confdir/$t_lport.log"
	fi
	;;
STOP)
	if [[ -f "$t_confdir/$t_lport.log" ]]; then
		killpid=$( cat "$t_confdir/$t_lport.log" | head -n 1 | $SEDC 's/^([0-9]+)\s.+/\1/' )
		kill "$killpid"
		if [[ $? = 0 ]]; then
			rm "$t_confdir/$t_lport.log"
			echo "Stopped tunnel to $t_lport"
		else # need to add another attempt here, with kill -9
			echo "Failed to kill tunnel to local port $t_lport : $killpid"
		fi
	else
		echo "This utility does not manage any remote tunnel to local port $t_lport."
	fi
	;;
STATUS)
	if [[ -f "$t_confdir/$t_lport.log" ]]; then
		echo -n "There is a tunnel running for port $t_lport: "
		tail -n 1 "$t_confdir/$t_lport.log"
	else
		echo "This utility does not manage any remote tunnel to local port $t_lport."
	fi
	;;
LIST)
	echo "Looking for ssh tunnels ..."
	$PSC | grep -E 'ssh .+[0-9]+:localhost:[0-9]+' | grep -v grep
	;;
esac
