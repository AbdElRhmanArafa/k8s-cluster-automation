#!/bin/bash
# check require packages
if ! command -v expect &> /dev/null
then
    echo "expect could not be found, installing..."
    sudo dnf install expect -y
else
    echo "expect is already installed"
fi

# Ensure SSH key exists
SSH_KEY="/home/arafa/.ssh/id_ed25519.pub"
if [ ! -f "$SSH_KEY" ]; then
    echo "Error: SSH key not found at $SSH_KEY. Generate one using ssh-keygen."
    exit 1
fi

# Copy SSH key to the server
password="it"
while IFS= read -r line; do
    echo "Copying SSH key to the server with IP: $line"
    
    # Use expect to handle password authentication
    
expect <<EOF
    spawn ssh-copy-id -o StrictHostKeyChecking=no -i "$SSH_KEY" "ubuntu@$line"
    expect "password:"
    send "$password\r"
    expect eof
EOF
done < ./vagrant/ip_address.txt

# Create inventory for ansible
echo "[master]" > ./inventory.ini
head -n 1 ./vagrant/ip_address.txt >> ./inventory.ini

echo "[workers]" >> ./inventory.ini
tail -n +2 ./vagrant/ip_address.txt >> ./inventory.ini

