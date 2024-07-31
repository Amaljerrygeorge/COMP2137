#!/bin/bash

verbose() {
  if [ "$VERBOSE" = true ]; then
    echo "$@"
  fi
}

update_hostname() {
  local new_hostname=$1

  if [ "$(hostname)" != "$new_hostname" ]; then
    verbose "Changing hostname to $new_hostname"
    echo "$new_hostname" > /etc/hostname
    hostnamectl set-hostname "$new_hostname"
    sed -i "s/127.0.1.1.*/127.0.1.1 $new_hostname/" /etc/hosts
    logger "Hostname changed to $new_hostname"
  else
    verbose "Hostname is already $new_hostname"
  fi
}

update_ip() {
  local new_ip=$1

  current_ip=$(hostname -I | awk '{print $1}')
  if [ "$current_ip" != "$new_ip" ]; then
    verbose "Changing IP address to $new_ip"
    sed -i "s/dhcp4: true/static_addresses: [$new_ip\/24]/" /etc/netplan/*.yaml
    netplan apply
    logger "IP address changed to $new_ip"
  else
    verbose "IP address is already $new_ip"
  fi
}

update_hosts_entry() {
  local hostname=$1
  local ip=$2

  if ! grep -q "$hostname" /etc/hosts; then
    verbose "Adding $hostname to /etc/hosts"
    echo "$ip $hostname" >> /etc/hosts
    logger "Added $hostname with IP $ip to /etc/hosts"
  else
    verbose "$hostname is already in /etc/hosts"
  fi
}

VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -verbose)
      VERBOSE=true
      shift
      ;;
    -name)
      NAME="$2"
      shift
      shift
      ;;
    -ip)
      IP="$2"
      shift
      shift
      ;;
    -hostentry)
      HOSTENTRY_NAME="$2"
      HOSTENTRY_IP="$3"
      shift
      shift
      shift
      ;;
    *)
      shift
      ;;
  esac
done

[ -n "$NAME" ] && update_hostname "$NAME"
[ -n "$IP" ] && update_ip "$IP"
[ -n "$HOSTENTRY_NAME" ] && update_hosts_entry "$HOSTENTRY_NAME" "$HOSTENTRY_IP"
