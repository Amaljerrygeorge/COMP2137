#!/bin/bash

verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "$@"
  fi
}

VERBOSE=false
if [ "$1" == "-verbose" ]; then
  VERBOSE=true
  shift
fi

SERVERS=("server1-mgmt" "server2-mgmt")
HOSTNAMES=("loghost" "webhost")
IPS=("192.168.16.3" "192.168.16.4")
OTHER_HOSTS=("webhost" "loghost")
OTHER_IPS=("192.168.16.4" "192.168.16.3")

for i in "${!SERVERS[@]}"; do
  SERVER=${SERVERS[$i]}
  HOSTNAME=${HOSTNAMES[$i]}
  IP=${IPS[$i]}
  OTHER_HOST=${OTHER_HOSTS[$i]}
  OTHER_IP=${OTHER_IPS[$i]}

  verbose "Transferring configure-host.sh to $SERVER"
  scp configure-host.sh remoteadmin@$SERVER:/root
  if [ $? -ne 0 ]; then
    echo "Error transferring configure-host.sh to $SERVER"
    exit 1
  fi

  verbose "Executing configure-host.sh on $SERVER"
  if [ "$VERBOSE" = true ]; then
    ssh remoteadmin@$SERVER -- /root/configure-host.sh -verbose -name $HOSTNAME -ip $IP -hostentry $OTHER_HOST $OTHER_IP
  else
    ssh remoteadmin@$SERVER -- /root/configure-host.sh -name $HOSTNAME -ip $IP -hostentry $OTHER_HOST $OTHER_IP
  fi

  if [ $? -ne 0 ]; then
    echo "Error executing configure-host.sh on $SERVER"
    exit 1
  fi
done

verbose "Updating local /etc/hosts file"
./configure-host.sh -hostentry loghost 192.168.16.3
if [ $? -ne 0 ]; then
  echo "Error updating /etc/hosts with loghost"
  exit 1
fi

./configure-host.sh -hostentry webhost 192.168.16.4
if [ $? -ne 0 ]; then
  echo "Error updating /etc/hosts with webhost"
  exit 1
fi

verbose "Configuration complete"
