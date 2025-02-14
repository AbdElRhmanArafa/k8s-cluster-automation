#!/bin/bash
# check require packages
sudo apt install expect -y

cd ./vagrant
# Check if the .vagrant directory exists
if [ -d ".vagrant" ]; then
    echo "Vagrant directory exists | cleaning up..."
    vagrant destroy -f
 fi

echo "Starting Vagrant..."
vagrant up 

# Wait for Vagrant to initialize
if [ $? -ne 0 ]; then
    echo "Error: Vagrant failed to start."
    exit 1
fi

# Check if the IP address file exists
if [ ! -f "./ip_address.txt" ]; then
    echo "Error: ip_address.txt file not found!"
    exit 1
fi


# Ensure SSH key exists
SSH_KEY="/home/arafa/.ssh/id_ed25519.pub"
if [ ! -f $SSH_KEY ]; then
    echo "Error: SSH key not found at $SSH_KEY. Generate one using ssh-keygen."
    exit 1
fi

# Copy SSH key to the server
password="it"
while IFS= read -r line; do
    echo "Copying SSH key to the server with IP: $line"
    
    # Use expect to handle password authentication
    
expect <<EOF
    spawn ssh-copy-id -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@$line
    expect "password:"
    send "$password\r"
    expect eof
EOF
done < ./ip_address.txt

# Create inventory for ansible
echo "[master]" > ../inventory.INI
head -n 1 ./ip_address.txt >> ./inventory.INI

echo "[workers]" >>./inventory.INI
tail -n +2 ./ip_address.txt >> ./inventory.INI

