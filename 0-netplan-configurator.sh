#!/bin/bash

# Script to configure Netplan interactively

CONFIG_FILE="/etc/netplan/50-cloud-init.yaml"
LOG_FILE="/var/log/netplan-config.log"

# Function to log messages
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

echo "Welcome to the Netplan network configurator."
log_message "Script started."

read -p "Enter the interface you want to configure (e.g., ens33): " INTERFACE

if [[ -z "$INTERFACE" ]]; then
    echo "No interface provided. Exiting."
    log_message "No interface provided. Script exited."
    exit 1
fi

read -p "Do you want to configure the network with a static IP or DHCP? (static/dhcp): " OPTION

if [[ "$OPTION" == "dhcp" ]]; then
    echo "Configuring the network to use DHCP..."
    log_message "Configuring $INTERFACE to use DHCP."
    cat <<EOF > $CONFIG_FILE
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: true
EOF
    echo "DHCP configuration written to $CONFIG_FILE"
    log_message "DHCP configuration written for $INTERFACE."

elif [[ "$OPTION" == "static" ]]; then
    echo "Configuring the network with a static IP..."
    log_message "Configuring $INTERFACE with a static IP."

    read -p "Enter the IP address (e.g., 192.168.0.1/24): " STATIC_IP
    read -p "Enter the gateway (e.g., 192.168.0.1): " GATEWAY
    read -p "Enter the DNS servers separated by commas (e.g., 8.8.8.8 or 8.8.8.8,8.8.4.4): " DNS
    IFS=',' read -ra DNS_ARRAY <<< "$DNS"

    echo "Writing static network configuration..."
    log_message "Writing static configuration for $INTERFACE."
    {
        echo "network:"
        echo "  version: 2"
        echo "  ethernets:"
        echo "    $INTERFACE:"
        echo "      dhcp4: no"
        echo "      addresses:"
        echo "        - $STATIC_IP"
        echo "      routes:"
        echo "        - to: default"
        echo "          via: $GATEWAY"
        echo "      nameservers:"
        echo "        addresses:"
        for DNS_ENTRY in "${DNS_ARRAY[@]}"; do
            echo "          - $DNS_ENTRY"
        done
    } > $CONFIG_FILE
    echo "Static configuration written to $CONFIG_FILE"
    log_message "Static configuration written for $INTERFACE."

else
    echo "Invalid option. Please run the script again and choose 'static' or 'dhcp'."
    log_message "Invalid option selected. Script exited."
    exit 1
fi

echo "Applying the network configuration with 'netplan apply'..."
log_message "Running 'netplan apply'."
netplan apply

if [[ $? -eq 0 ]]; then
    echo "Network configuration applied successfully."
    log_message "Network configuration applied successfully."
else
    echo "There was an error applying the configuration. Please check the file $CONFIG_FILE."
    log_message "Error applying network configuration. Check $CONFIG_FILE."
fi

log_message "Script completed."

