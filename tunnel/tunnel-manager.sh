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

# =========================================
# Bash argument extraction example
#
# need to switch this to native bash regexing
# ===

function getarg {
	# $1 - arg
	# $2 - label
	# $3+ - value(s)
	local a_arg=$1
	shift

	local a_label=$1
	shift

	local a_match=$1
	shift

	echo "$a_arg" | grep -E "^$a_label=$a_match$" | sed -e "s/$a_label=//"
}

function matcharg {
	# $1 - argument
	# $2+ - values
	local a_arg=$1
	shift

	local a_match=$( echo "$@" | tr ',' '\n' )

	echo -e "$a_match" | grep "^$a_arg$"
}

function argextract {
	#$1 - argument
	#$2 - series of capturing patterns captured sequentially
	# This is a bit kludgy and needs refining
	
	local a_arg=$1
	shift
	
	#echo "Arg $a_arg"

	local var
	for var in "$@"; do
		#echo "Pat $var"
		a_arg=$(echo $a_arg | $SEDC "s|^$var$|\1|")
	done
	echo $a_arg
}

# ===== Usage

for var in "$@"; do
	if [[ $( matcharg "$var" "--help,-h,/h" ) != "" ]]; then
		cat <<EOHELP
Remote Tunnel Manager

$0 - Open a remote tunnel

Assuming you can tunnel to a remote server, this script is intended to take care of the logic of testing and managing a remote tunnel connection

== Usage ==

Full set of arguments

	$0 ACTION --lport=LPORT [--rport=RPORT --server=SERVER --user=USER --cport=CPORT]

or short hand:

	$0 START --ssh=USER@SERVER:CPORT --tunnel=RPORT-LPORT

ACTION
	Any of "START", "STOP" or "STATUS" ; only START requires the full set of arguments
	STOP and STATUS only need the local port number to stop the tunnel, if it exists

LPORT
	The local port you want to forward the tunnel to

Establishing a connection with START requires these additional parameters

RPORT
	The port on the remote server which is listening

SERVER
	The remote server which is the front end of the tunnel

USER
	The user on the remote server

CPORT
	The SSH port of the remote server

EOHELP
		exit 0
	fi
	
	l_action=$( matcharg "$var" "START,STOP,STATUS"  )
	if [[ x$l_action != x ]]; then t_action=$l_action; fi

	# Shorthand for the ports: --tunnel=rport-lport
	l_ports=$( getarg "$var" "--tunnel" "[1-9][0-9]+-[1-9][0-9]+" )
	if [[ x$l_ports != x ]]; then
		t_lport=$( argextract "$l_ports" ".*-([1-9][0-9]+)" )
		t_rport=$( argextract "$l_ports" "([1-9][0-9]+)-.*" )
	fi

	l_lport=$( getarg "$var" "--lport" "[1-9][0-9]+"  )
	if [[ x$l_lport != x ]]; then t_lport=$l_lport; fi

	l_rport=$( getarg "$var" "--rport" "[1-9][0-9]+" )
	if [[ x$l_rport != x ]]; then t_rport=$l_rport; fi

	# Here's a shorthand: --ssh=user@server:port
	l_ssh=$( getarg "$var" "--ssh" "[a-zA-Z0-9_-]+@[^.][a-z0-9\\.-]+[^.]:[1-9][0-9]+" )
	if [[ x$l_ssh != x ]]; then
		# An old man in a care home is complaining about the eggs:
		# "They taste of nothing. Nothing. Just nothing."
		# To which the nurse replies, "I just cook the eggs - I don't lay them."

		t_ruser=$( argextract "$l_ssh" "([a-zA-Z0-9_-]+)@.*" )
		t_rserv=$( argextract "$l_ssh" ".*@([^.][a-z0-9\\.-]+[^.]):.*" )
		t_cport=$( argextract "$l_ssh" ".*:([1-9][0-9]+)" )
	fi
	
	l_rserv=$( getarg "$var" "--server" "[^.][a-z0-9\\.-]+[^.]" )
	if [[ x$l_rserv != x ]]; then t_rserv=$l_rserv; fi

	l_ruser=$( getarg "$var" "--user" "[a-zA-Z0-9_-]+" )
	if [[ x$l_ruser != x ]]; then t_ruser=$l_ruser; fi

	l_cport=$( getarg "$var" "--cport" "[1-9][0-9]+" )
        if [[ x$l_cport != x ]]; then t_cport=$l_cport; fi
done

# ===
# Argument processing is done
# ================================

l_verbose=$( matcharg "$var" "-v,--verbose"  )
if [[ x$l_verbose != x ]]; then

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
