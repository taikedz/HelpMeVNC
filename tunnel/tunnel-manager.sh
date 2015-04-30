#! /bin/bash

# Script to automatically start or kill a tunnel
# Saves information to a ~/.config/helpmesee/tunnels/PORT.pid containing the PID of the SSH instance

# TODO : extra features to include
# STATUSALL - display the statuses of all tunnels

# Declare global variables

t_confdir=$HOME/.config/helpmesee/tunnels
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

	echo "Processing [$var]"

	matcher="^(START|STOP|STATUS)$"
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
EOF

fi

# ============
# Need to be able to find connections we did not initiate
# Would be nice to be able to manage tunnels by name

echo "Let's see..."

case $t_action in
START)
	if [[ ! -f "$t_confdir/$t_lport.log" ]]; then
		# TODO - Somehow we have to pass the password
		# which is probably not possible if programatically, so need to pass
		# a key file
		set -e
		ssh -fNC -R "$t_rport:localhost:$t_lport" "$t_ruser@$t_rserv" -p $t_cport #>> "$t_confdir/$t_lport.log" # remember to match the below next!
		pidline=$( $PSC | grep "$t_rport:localhost:$t_lport $t_ruser@$t_rserv" | grep -v grep )
		# extract PID
		pid=$( echo $pidline | $SEDC "s|^$USER\\s+([0-9]+)\\s+.+$|\1|" )
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
esac
