#!/bin/bash

help() {
    echo "Usage: $0 [options]"
    echo "  -h          Display this help message"
    echo "  -m N        Set number of master nodes (default: 1)"
    echo "  -w N        Set number of worker nodes (default: 2)"
    echo "  -p          Enable provisioning"
    echo "  -c CNI      Set Container Network Interface plugin:"
    echo "              Options: flannel, calico, cilium, weave, kuberouter (default: calico)"
    echo "  -d          Destroy VMs instead of creating them"
}

metadata() {
    echo "Kubernetes Cluster Automation"
    echo "----------------------------"
    echo "Starting up Vagrant VMs for Kubernetes cluster"
    echo "This script will set up a Kubernetes cluster using Vagrant and ansible."
    
    # Calculate total nodes
    NODE_COUNT=$((MASTER_COUNT + WORKER_COUNT))
    if [ "$HA_PROXY" = true ]; then
        NODE_COUNT_print=$((NODE_COUNT + 1))
        echo "Total nodes in the cluster: $NODE_COUNT_print"
        echo "Setting up cluster with $MASTER_COUNT master(s) and $WORKER_COUNT worker(s)  and one HA Proxy (total: $NODE_COUNT_print nodes)"
    else
        echo "Total nodes in the cluster: $NODE_COUNT"
        echo "Setting up cluster with $MASTER_COUNT master(s) and $WORKER_COUNT worker(s) (total: $NODE_COUNT nodes)"
    fi
}
# Function to save variables to cache file
save_to_cache() {
    local CACHE_FILE="/home/arafa/Documents/project_github/k8s-cluster-automation/cache"
    echo "Saving cluster configuration to cache..."
    
    # Save the variables to cache file
    cat > "$CACHE_FILE" << EOF
MASTER_COUNT=$MASTER_COUNT
WORKER_COUNT=$WORKER_COUNT
NODE_COUNT=$NODE_COUNT
CNI_PLUGIN=$CNI_PLUGIN
HA_PROXY=$HA_PROXY
EOF
    echo "Configuration saved to $CACHE_FILE"
}

# Function to load variables from cache file
load_from_cache() {
    local CACHE_FILE="/home/arafa/Documents/project_github/k8s-cluster-automation/cache"
    
    if [ -f "$CACHE_FILE" ]; then
        echo "Loading cluster configuration from cache..."
        # Source the cache file to load the variables
        source "$CACHE_FILE"
        echo "Loaded configuration: $MASTER_COUNT master(s), $WORKER_COUNT worker(s), CNI: $CNI_PLUGIN, HA_PROXY: $HA_PROXY"
    else
        echo "Warning: No cache file found. Using default values for destroy operation."
    fi
}

# Function to prepare inventory file for Ansible based on IP addresses
prepare_inventory() {
    local IP_FILE="./vagrant/ip_address.txt"
    local INVENTORY_FILE="./inventory.INI"
    
    echo "Preparing inventory file for Ansible..."
    
    # Check if IP address file exists
    if [ ! -f "$IP_FILE" ]; then
        echo "Error: IP address file not found at $IP_FILE"
        return 1
    fi

    # Create inventory file with master and worker sections
    echo "[master]" > "$INVENTORY_FILE"
    # Read IP addresses from file and add to inventory
    bool_var_workers=false
    bool_var_haproxy=false
    while IFS=: read -r hostname ip; do
        # Remove any leading/trailing whitespace
        hostname=$(echo "$hostname" | xargs)
        ip=$(echo "$ip" | xargs)
        
        echo "Processing $hostname with IP: $ip"

        
        # Add to appropriate section in inventory
        if [[ "$hostname" == master* ]]; then
            echo "$ip" >> "$INVENTORY_FILE"
        elif [[ "$hostname" == worker* ]]; then
            if [ "$bool_var_workers" = false ]; then
                echo "[workers]" >> "$INVENTORY_FILE"
                bool_var_workers=true
            fi
            # Find the [workers] section and add the IP after it
            sed -i "/\[workers\]/a\\$ip" "$INVENTORY_FILE"
        elif [[ "$hostname" == haproxy* ]]; then
            if [ "$bool_var_haproxy" = false ]; then
                echo "[haproxy]" >> "$INVENTORY_FILE"
                bool_var_haproxy=true
            fi
            # Add the IP under the haproxy section
            echo "$ip" >> "$INVENTORY_FILE"
        fi
    done < "$IP_FILE"
    
    echo "Inventory file prepared successfully at $INVENTORY_FILE"
}

main() {
    # Change to the vagrant directory to use the Vagrantfile there
    cd vagrant || { echo "Failed to change to vagrant directory"; exit 1; }
    
    # Check if we need to destroy VMs
    if [ "$DESTROY" = "true" ]; then
        # Load configuration from cache before destroying
        cd .. || { echo "Failed to return to original directory"; exit 1; }
        load_from_cache
        cd vagrant || { echo "Failed to change to vagrant directory"; exit 1; }
        
        # Export environment variables for Vagrant
        export NODE_COUNT
        export MASTER_COUNT
        export WORKER_COUNT
        export CNI_PLUGIN
        export HA_PROXY
        
        echo "Destroying all VMs..."
        vagrant destroy -f
        cd .. || { echo "Failed to return to original directory"; exit 1; }
        echo "All VMs have been destroyed."
        exit 0
    fi
    
    # Not destroying, so show metadata and check for stray volumes
    metadata
    # Save the configuration to cache before starting VMs
    cd .. || { echo "Failed to return to original directory"; exit 1; }
    save_to_cache
    cd vagrant || { echo "Failed to change to vagrant directory"; exit 1; }
    
    # Export environment variables for Vagrant
    export NODE_COUNT
    export MASTER_COUNT
    export WORKER_COUNT
    export CNI_PLUGIN
    export HA_PROXY
    
    echo "Selected CNI plugin: $CNI_PLUGIN"
    
    # Run vagrant up command with provisioning if enabled
    echo "Starting Vagrant VMs..."
    if [ "$PROVISION" = "true" ]; then
        vagrant up --provision
    else
        vagrant up
    fi
    
    # Return to the original directory
    cd .. || { echo "Failed to return to original directory"; exit 1; }
    
    echo "Vagrant VMs are up. Preparing Ansible inventory..."
    
    # Prepare inventory file for Ansible
    prepare_inventory
    
    echo "Inventory prepared. You can now proceed with Ansible provisioning."
}

# Set default values
MASTER_COUNT=1
WORKER_COUNT=2
PROVISION=false
CNI_PLUGIN="calico"
DESTROY=false
HA_PROXY=false


# Process command line arguments using getopts
while getopts ":hm:w:pc:d" opt; do
    case $opt in
        h)
            help
            exit 0
            ;;
        m)
            MASTER_COUNT=$OPTARG
            ;;
        w)
            WORKER_COUNT=$OPTARG
            ;;
        p)
            PROVISION=true
            ;;
        c)
            # Validate CNI option
            case "${OPTARG,,}" in
                flannel|calico|cilium|weave|kuberouter)
                    CNI_PLUGIN="${OPTARG,,}"
                    ;;
                *)
                    echo "Invalid CNI plugin: $OPTARG" >&2
                    echo "Valid options are: flannel, calico, cilium, weave, kuberouter" >&2
                    exit 1
                    ;;
            esac
            ;;
        d)
            DESTROY=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            help
            exit 1
            ;;
    esac
done

if [[ $MASTER_COUNT -gt 1 ]]; then
    echo " you are trying to create a multi-master cluster HA so you need HA proxy node so it will be created automatically"
    HA_PROXY=true
    echo "HA Proxy enabled: $HA_PROXY"

fi
# Execute main function
main
# prepare_inventory
