#!/bin/bash

# mongos - Startup script for mongos

# chkconfig: 35 85 15
# description: Mongo is a scalable, document-oriented database.
# processname: mongos
# config: /etc/mongos.conf

. /etc/rc.d/init.d/functions

# NOTE: if you change any OPTIONS here, you get what you pay for:
# this script assumes all options are in the config file.
CONFIGFILE="/etc/mongos.conf"
OPTIONS=" -f $CONFIGFILE"

mongos=${MONGOS-/usr/bin/mongos}

MONGO_USER=mongod
MONGO_GROUP=mongod

# All variables set before this point can be overridden by users, by
# setting them directly in the SYSCONFIG file. Use this to explicitly
# override these values, at your own risk.
SYSCONFIG="/etc/sysconfig/mongod"
if [ -f "$SYSCONFIG" ]; then
    . "$SYSCONFIG"
fi

# Handle NUMA access to CPUs (SERVER-3574)
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null
then
    NUMACTL="numactl $NUMACTL_ARGS"
else
    NUMACTL=""
fi

# things from mongos.conf get there by mongos reading it
PIDFILEPATH="`awk -F'[:=]' -v IGNORECASE=1 '/^[[:blank:]]*(processManagement\.)?pidfilepath[[:blank:]]*[:=][[:blank:]]*/{print $2}' \"$CONFIGFILE\" | tr -d \"[:blank:]\\"'\" | awk -F'#' '{print $1}'`"
PIDDIR=`dirname $PIDFILEPATH`

start()
{
  # Make sure the default pidfile directory exists
  if [ ! -d $PIDDIR ]; then
    install -d -m 0755 -o $MONGO_USER -g $MONGO_GROUP $PIDDIR
  fi

  # Make sure the pidfile does not exist
  if [ -f "$PIDFILEPATH" ]; then
      echo "Error starting mongos. $PIDFILEPATH exists."
      RETVAL=1
      return
  fi

  # Recommended ulimit values for mongos or mongos
  # See http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings
  #
  ulimit -f unlimited
  ulimit -t unlimited
  ulimit -v unlimited
  ulimit -n 64000
  ulimit -m unlimited
  ulimit -u 64000
  ulimit -l unlimited

  echo -n $"Starting mongos: "
  daemon --user "$MONGO_USER" --check $mongos "$NUMACTL $mongos $OPTIONS >/dev/null 2>&1"
  RETVAL=$?
  echo
  [ $RETVAL -eq 0 ] && touch /var/lock/subsys/mongos
}

stop()
{
  echo -n $"Stopping mongos: "
  mongo_killproc "$PIDFILEPATH" $mongos
  RETVAL=$?
  echo
  [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/mongos
}

restart () {
        stop
        start
}

# Send TERM signal to process and wait up to 300 seconds for process to go away.
# If process is still alive after 300 seconds, send KILL signal.
# Built-in killproc() (found in /etc/init.d/functions) is on certain versions of Linux
# where it sleeps for the full $delay seconds if process does not respond fast enough to
# the initial TERM signal.
mongo_killproc()
{
  local pid_file=$1
  local procname=$2
  local -i delay=300
  local -i duration=10
  local pid=`pidofproc -p "${pid_file}" ${procname}`

  if [ ! -f "${pid_file}" ]; then
     echo "No PID file detected, nothing to stop"
     return 0
  fi

  # Per the man page the process name should always be the second
  # field. In our case mongos is wrapped in parens hence the parens in
  # the if condition below.
  local stat_procname=`cat /proc/$pid/stat | cut -d" " -f2`
  # $procname is the full path to the mongos binary but the process
  # name will only match the binary's file name.
  local binary_name=`basename $procname`
  if [ "($binary_name)" != "$stat_procname" ]; then
     echo "PID file may have been tampered with, refusing to kill process"
     echo "Expected (${binary_name}) but found ${stat_procname}"
     return 1
  fi

  # This doesn't actually "daemonize" this process. All this function
  # does (defined in /etc/init.d/function) is run a process as another
  # user in a way that doesn't require sudo or other packages which
  # are not guaranteed to exist on any given system.
  #
  # The check flag here can be ignored it doesn't do anything except
  # prevent the daemon function's PID checking from throwing an error.
  daemon --check "$mongos" --user "$MONGO_USER" "kill -TERM $pid >/dev/null 2>&1"
  usleep 100000
  local -i x=0
  while [ $x -le $delay ] && checkpid $pid; do
    sleep $duration
    x=$(( $x + $duration))
  done

  daemon --check "$mongos" --user "$MONGO_USER" "kill -KILL $pid >/dev/null 2>&1"
  usleep 100000

  checkpid $pid # returns 0 only if the process exists
  local RC=$?
  [ "$RC" -eq 0 ] && failure "${procname} shutdown" || rm -f "${pid_file}"; success "${procname} shutdown"
  RC=$((! $RC)) # invert return code so we return 0 when process is dead.
  return $RC
}

RETVAL=0

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart|reload|force-reload)
    restart
    ;;
  condrestart)
    [ -f /var/lock/subsys/mongos ] && restart || :
    ;;
  status)
    status $mongos
    RETVAL=$?
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
    RETVAL=1
esac

exit $RETVAL
