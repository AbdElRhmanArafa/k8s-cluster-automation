#!/bin/bash

sudo apt-get update

# Set password for ubuntu user
echo 'vagrant:it' | sudo chpasswd

# change password for ubuntu user
echo 'ubuntu:it' | sudo chpasswd

# make ubuntu user passwordless sudo No password required
echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' | sudo EDITOR='tee -a' visudo

# Enable password authentication
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM no/UsePAM yes/g' /etc/ssh/sshd_config

# Restart SSH service
sudo systemctl restart sshd
# Install Python 
sudo apt-get install -y python3 python3-pip
