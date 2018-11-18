#! /bin/sh


#----------------------------------------------------------------------
# parameters
#----------------------------------------------------------------------
INITD="$1"
CMD="$2"
[ -n "$3" ] && WAIT="$3" || WAIT=1


#----------------------------------------------------------------------
# internal variable
#----------------------------------------------------------------------
SLEEP=""


#----------------------------------------------------------------------
# start service
#----------------------------------------------------------------------
start() {
	trap "" INT QUIT TSTP EXIT
	if [ -d "$INITD" ]; then
		echo "Launching initialization scripts"
		for f in $INITD/I*; do
			[ -e "$f" ] && . "$f"
		done
		for f in $INITD/S*; do
			[ -x "$f" ] && "$f" start
		done
	else
		echo "error: %s directory not found" 1>&2
		exit 1
	fi
}


#----------------------------------------------------------------------
# stop service
#----------------------------------------------------------------------
stop() {
	trap "" INT QUIT TSTP EXIT
	if [ -d "$INITD" ]; then
		echo "Launching termination scripts"
		for f in $INITD/K*; do
			[ -x "$f" ] && "$f" stop
		done
	else
		echo "error: %s directory not found" 1>&2
		exit 1
	fi
	if [ -n "$WAIT" ]; then
		/bin/sleep "$WAIT"
	fi
}


#----------------------------------------------------------------------
# execute scripts
#----------------------------------------------------------------------
execute() {
	if [ -d "$INITD" ]; then
		echo "Executing initialization scripts"
		for f in $INITD/I*; do
			[ -e "$f" ] && . "$f"
		done
		for f in $INITD/E*; do
			[ -x "$f" ] && "$f" start
		done
	else
		echo "error: %s directory not found" 1>&2
		exit 1
	fi
}


#----------------------------------------------------------------------
# restart service
#----------------------------------------------------------------------
restart() {
	stop 
	start
}


#----------------------------------------------------------------------
# keep service
#----------------------------------------------------------------------
_term() {
	trap "" TERM INT
	stop
	[ -n "$SLEEP" ] && kill $SLEEP 2> /dev/null
	SLEEP=""
	exit 0
}

keep() {
	start
	trap _term TERM INT TSTP QUIT EXIT
	while : 
	do
		/bin/sleep 3600 &
		SLEEP=$!
		wait $!
	done
}


#----------------------------------------------------------------------
# main routine
#----------------------------------------------------------------------
_help() {
	echo "usage: $0 TARGET {start|stop|restart|keep}"
	exit 0
}

if [ -z "$CMD" ] || [ -z "$INITD" ]; then
	_help
	exit 0
fi

case "$CMD" in
	start)
		start
		;;
	stop)
		stop
		;;
	restart)
		restart
		;;
	keep)
		keep
		;;
	execute)
		execute
		;;
	*)
		_help
		exit 0
esac




