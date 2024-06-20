#!/bin/bash

#system information
USERNAME=$(whoami)
DATE=$(date)
HOSTNAME=$(hostname)
OS=$(lsb_release -d | awk -F"\t" '{print $2}')
UPTIME=$(uptime -p)

#hardware information
CPU=$(lscpu | grep "Model name" | awk -F: '{print $2}' | sed 's/^ //')
SPEED=$(lscpu | grep "CPU MHz" | awk -F: '{print $2}' | sed 's/^ //')
RAM=$(free -h | grep Mem | awk '{print $2}')
DISKS=$(lsblk -d -o NAME,MODEL,SIZE | grep -E 'sd|nvme' | awk '{print $1 ": " $2 ", " $3}' | paste -sd, -)
VIDEO=$(lspci | grep -i vga | awk -F: '{print $3}' | sed 's/^ //')

#network information
FQDN=$(hostname --fqdn)
HOSTADDR=$(hostname -I | awk '{print $1}')
GATEWAY=$(ip r | grep default | awk '{print $3}')
DNS=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | paste -sd, -)
NETCARD=$(lshw -class network | grep "product" | awk -F: '{print $2}' | sed 's/^ //' | head -n 1)
NETADDR=$(ip a | grep inet | grep -v "127.0.0.1" | awk '{print $2}' | head -n 1)

#system status
USERS=$(who | awk '{print $1}' | paste -sd, -)
DISKSPACE=$(df -h --output=source,avail | grep "^/" | awk '{print $1 ": " $2}' | paste -sd, -)
PROCCOUNT=$(ps -e --no-headers | wc -l)
LOADAVG=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')
MEMALLOC=$(free -h | awk 'NR==2{printf "Total: %s, Used: %s, Free: %s", $2, $3, $4}')
PORTS=$(ss -tuln | grep LISTEN | awk '{print $5}' | paste -sd, -)
UFW=$(sudo ufw status numbered | grep "\[ \d\]")

# Output
cat << EOF

System Report generated by $USERNAME, $DATE

System Information
------------------
Hostname: $HOSTNAME
OS: $OS
Uptime: $UPTIME

Hardware Information
--------------------
CPU: $CPU
Speed: $SPEED
RAM: $RAM
Disk(s): $DISKS
Video: $VIDEO

Network Information
-------------------
FQDN: $FQDN
Host Address: $HOSTADDR
Gateway IP: $GATEWAY
DNS Server: $DNS

InterfaceName: $NETCARD
IP Address: $NETADDR

System Status
-------------
Users Logged In: $USERS
Disk Space: $DISKSPACE
Process Count: $PROCCOUNT
Load Averages: $LOADAVG
Memory Allocation: $MEMALLOC
Listening Network Ports: $PORTS
UFW Rules: $UFW

EOF
