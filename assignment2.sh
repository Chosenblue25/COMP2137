#!/bin/bash

# Function to display labeled output
display_output() {
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "$1"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
}

# Function to check if a package is installed
package_installed() {
    dpkg -s "$1" &> /dev/null
}

# Function to add users with ssh keys and sudo access
add_users() {
    local users=( "dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda" )
    
    for user in "${users[@]}"; do
        if ! id "$user" &> /dev/null; then
            useradd -m -s /bin/bash "$user"
            display_output "User $user added"
        fi

        # Adding ssh keys for rsa and ed25519 algorithms
        mkdir -p /home/$user/.ssh
        cat << EOF >> /home/$user/.ssh/authorized_keys
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
EOF

        # Set correct permissions
        chmod 700 /home/$user/.ssh
        chmod 600 /home/$user/.ssh/authorized_keys

        # Add sudo access for user dennis
        if [[ "$user" == "dennis" ]]; then
            usermod -aG sudo "$user"
            display_output "User $user granted sudo access"
        fi
    done
}

# Function to configure network interface
configure_network() {
    local netplan_file="50-cloud-init.yaml"

    # Check if netplan configuration file exists
    if [ ! -f "$netplan_file" ]; then
        display_output "Netplan configuration file not found: $netplan_file"
        
        # Create the netplan configuration file
        touch "$netplan_file" || { display_output "Error: Unable to create $netplan_file"; exit 1; }
        chmod 600 "$netplan_file"
        
        # Add initial configuration content to the newly created file
        cat << EOF > "$netplan_file"
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search: [home.arpa, localdomain]
EOF
        display_output "Netplan configuration file created: $netplan_file"
    fi

    # Check if the interface configuration is already present
    if grep -q "192.168.16.21" "$netplan_file"; then
        display_output "Network interface configuration already set"
    else
        # Append the interface configuration to the netplan file
        cat << EOF >> "$netplan_file"
network:
  ethernets:
    eth0:
      addresses:
        - 192.168.16.21/24
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search: [home.arpa, localdomain]
EOF
	display_output "Network interface configured successfully"
    fi
    # Apply the netplan configuration
    netplan apply
}


# Function to install necessary software
install_software() {
    local packages=( "apache2" "squid" "ufw" )

    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            apt-get install -y -q "$pkg" 2>/dev/null
            display_output "Package $pkg installed"
        else
            display_output "Package $pkg is already installed"
        fi
    done
}

# Function to configure firewall
configure_firewall() {
    # Allow SSH only on the mgmt network
    ufw allow from 192.168.16.0/24 to any port 22

    # Allow HTTP on both interfaces
    ufw allow http

    # Allow web proxy on both interfaces
    ufw allow 3128/tcp

    # Enable firewall
    ufw --force enable

    display_output "Firewall configured"
}

# Main function
main() {
    display_output "Starting system configuration..."

    add_users
    configure_network
    update_hosts_file
    install_software
    configure_firewall

    display_output "System configuration complete."
}

# Execute the main function because why not, another function to make it more elegant
main