#!/bin/bash

# Update system packages
sudo apt-get update

# Create ubuntu user if it doesn't exist
if ! id "ubuntu" &>/dev/null; then
    sudo useradd -m -s /bin/bash ubuntu
    echo "ubuntu:it" | sudo chpasswd
    echo "User 'ubuntu' created with password 'it'"
fi

# Set password for vagrant and ubuntu users
echo 'vagrant:it' | sudo chpasswd
echo 'ubuntu:it' | sudo chpasswd

# Make ubuntu user passwordless sudo - No password required
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo

# Enable password authentication in SSH
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM no/UsePAM yes/g' /etc/ssh/sshd_config

# Create .ssh directory for ubuntu user
sudo mkdir -p /home/ubuntu/.ssh
sudo chmod 700 /home/ubuntu/.ssh
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh

# Add the SSH public key to authorized_keys if it exists
if [ -f /tmp/id_ed25519.pub ]; then
    sudo cat /tmp/id_ed25519.pub >> /home/ubuntu/.ssh/authorized_keys
    sudo chmod 600 /home/ubuntu/.ssh/authorized_keys
    sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
    echo "SSH key added for ubuntu user"
else
    echo "Warning: No SSH key found at /tmp/id_ed25519.pub"
fi

# Restart SSH service
sudo systemctl restart sshd

# Install Python 
sudo apt-get install -y python3 python3-pip
