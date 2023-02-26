#!/bin/bash
# this script was made by Andrei Savchenko
# ver v1.0

running=true
name="myapp.sh"
config_file="/opt/myapp/myapp.conf"
interval="5s"
backwardLines="1000"

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo "Usage: $name [FILE] [PATTERN]

- Commandline options will be used instead of config if specified.
- Run $name without parameters if you want to use config file.

config file location: $config_file
  e.g.
        logfile=/home/user/myapp.log
        pattern=\"pattern to find\""
    exit 1
fi

# Do not edit vars below
logfile=$1
pattern=$2
serviceName=""
startTime=""
stringBuf=""
cdate=""

printUsage(){
echo "Usage: ./$name [FILE] [PATTERN]
Try './$name --help' for more information."
exit 1
}

confCheck(){
if [ -f $config_file ]; then
  . $config_file
  if [[ -z $logfile ]] || [[ -z $pattern ]]; then
    echo "Bad config. Exiting..."
    return 1
  else
    if [ -f $logfile ]; then
      return 0
    else
      echo "File '$logfile' not found."
      exit 1
    fi
  fi
else
  echo "Config file $config_file not found!"
  return 1
fi
}

optCheck(){
if [ -z $logfile ]; then
  return 1
fi
if [ -z $pattern ]; then
  printUsage
else
  if [ -f $logfile ]; then
    return 0
  else
    echo "File '$logfile' not found."
    exit 1
  fi
fi
}

getLastEnryTime(){
startTime=("`tail -n 1 $logfile | awk -F"[\t ]+" '{print $1,$2,$3}'`")
}

getCurrentTime(){
cdate=("`date "+%b %d %T"`")
}

findServiceName(){
if tail -n $backwardLines $logfile | tac | sed "/$startTime/q" | grep -m 1 $pattern &>0; then
  echo "String found! Time to get name of the service..."
  serviceName=(`tail -n $backwardLines $logfile | tac | sed "/$startTime/q" | grep -m 1 $pattern | awk -F"[\t-:]+" '{print $4}'`)
else
  return 1
fi
}

mainLoop(){
getLastEnryTime
sleep 1s
while $running; do
if findServiceName; then
  echo "Restarting $serviceName service..."
  systemctl restart backend@$serviceName.service
  getCurrentTime
  echo "$cdate localhost worker-$name: Service backend@$serviceName.service has been restarted." >> $logfile
  startTime=$cdate
  echo "Continue in $interval..."
  sleep $interval
else
  echo "Pattern not found. Retrying in $interval..."
  sleep $interval
fi
done
}

startFunc(){
if optCheck; then
  echo "Started with given params: looking into $logfile and waiting for new entries that match the \"$pattern\"..."
  mainLoop
else
  if confCheck; then
    echo "Started with $config_file: looking into $logfile and waiting for new entries that match the \"$pattern\"..."
    mainLoop
  else
    printUsage
  fi
fi
}

startFunc
