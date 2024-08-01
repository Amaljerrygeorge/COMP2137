#!/bin/bash

TARGET_IP="192.168.16.21"
TARGET_NETPLAN_CONFIG="/etc/netplan/50-cloud-init.yaml"
TARGET_HOSTS_FILE="/etc/hosts"
USER_LIST=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
SUDO_USER="dennis"
PUBLIC_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

echo "Updating network interface configuration..."
if ! grep -q "$TARGET_IP" $TARGET_NETPLAN_CONFIG; then
    sudo sed -i "/addresses:/c\            addresses: [$TARGET_IP/24]" $TARGET_NETPLAN_CONFIG
    sudo netplan apply
    echo "Network interface updated."
else
    echo "Network interface already configured."
fi

echo "Updating /etc/hosts file..."
if ! grep -q "$TARGET_IP server1" $TARGET_HOSTS_FILE; then
    sudo sed -i "/server1/d" $TARGET_HOSTS_FILE
    echo "$TARGET_IP server1" | sudo tee -a $TARGET_HOSTS_FILE
    echo "/etc/hosts updated."
else
    echo "/etc/hosts already configured."
fi

echo "Installing required software..."
sudo apt-get update
sudo apt-get install -y apache2 squid ufw
echo "Software installation completed."

echo "Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh from 192.168.16.0/24 to any port 22
sudo ufw allow http
sudo ufw allow 3128/tcp
sudo ufw --force enable
echo "Firewall configuration completed."

echo "Creating user accounts and configuring SSH..."
for user in "${USER_LIST[@]}"; do
    if id "$user" &>/dev/null; then
        echo "User $user already exists."
    else
        sudo adduser --disabled-password --gecos "" "$user"
        sudo mkdir -p /home/"$user"/.ssh
        sudo chown "$user":"$user" /home/"$user"/.ssh
        sudo chmod 700 /home/"$user"/.ssh
        ssh-keygen -t rsa -b 2048 -f /home/"$user"/.ssh/id_rsa -N ""
        ssh-keygen -t ed25519 -f /home/"$user"/.ssh/id_ed25519 -N ""
        sudo sh -c "cat /home/$user/.ssh/id_rsa.pub >> /home/$user/.ssh/authorized_keys"
        sudo sh -c "cat /home/$user/.ssh/id_ed25519.pub >> /home/$user/.ssh/authorized_keys"
        sudo chown "$user":"$user" /home/"$user"/.ssh/authorized_keys
        sudo chmod 600 /home/"$user"/.ssh/authorized_keys
    fi
done

echo "Granting sudo access to $SUDO_USER..."
if ! sudo getent group sudo | grep -q "$SUDO_USER"; then
    sudo usermod -aG sudo "$SUDO_USER"
    echo "$PUBLIC_SSH_KEY" | sudo tee -a /home/"$SUDO_USER"/.ssh/authorized_keys
    echo "Sudo access granted to $SUDO_USER."
else
    echo "$SUDO_USER already has sudo access."
fi

echo "Script execution completed."
