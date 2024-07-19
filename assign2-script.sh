#!/bin/bash

echo "Starting assignment2.sh..."

NET_INTERFACE="eth0"
HOSTS_FILE="/etc/hosts"
UFW_LOG_FILE="/var/log/ufw.log"
USERS=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

update_netplan() {
    echo "Updating netplan configuration..."
    cp /etc/netplan/*.yaml /etc/netplan/backup.yaml
    cat <<EOF > /etc/netplan/01-netcfg.yaml
    network:
      version: 2
      ethernets:
        $NET_INTERFACE:
          addresses:
            - 192.168.16.21/24
          gateway4: 192.168.16.1
          nameservers:
            addresses:
              - 8.8.8.8
              - 8.8.4.4
    EOF
    netplan apply
}

update_hosts_file() {
    echo "Updating /etc/hosts file..."
    cp $HOSTS_FILE ${HOSTS_FILE}.bak
    sed -i 's/192.168.16.20/server1/g' $HOSTS_FILE
}

install_software() {
    echo "Installing software..."
    apt-get update
    apt-get install -y apache2 squid
    systemctl start apache2
    systemctl enable apache2
    systemctl start squid
    systemctl enable squid
}

configure_firewall() {
    echo "Configuring firewall..."
    ufw reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 3128/tcp
    ufw enable
}

create_users() {
    echo "Creating users..."
    for user in "${USERS[@]}"; do
        if id "$user" &>/dev/null; then
            echo "User $user already exists"
        else
            useradd -m -s /bin/bash $user
            mkdir -p /home/$user/.ssh
            chown $user:$user /home/$user/.ssh
            chmod 700 /home/$user/.ssh
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/$user/.ssh/authorized_keys
            chown $user:$user /home/$user/.ssh/authorized_keys
            chmod 600 /home/$user/.ssh/authorized_keys
        fi
    done
    usermod -aG sudo dennis
}

update_netplan
update_hosts_file
install_software
configure_firewall
create_users

echo "Script execution completed."
