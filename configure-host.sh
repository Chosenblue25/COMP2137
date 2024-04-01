#!/bin/bash

# Function to log changes
log_changes() {
    local message=$1
    if [ "$verbose" = true ]; then
        echo "$message"
    else
        logger -p user.notice "$message"
    fi
}

# Function to handle TERM, HUP, and INT signals
trap '' TERM HUP INT

# Default verbose mode
verbose=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -verbose)
        verbose=true
        shift
        ;;
        -name)
        desiredName="$2"
        shift
        shift
        ;;
        -ip)
        desiredIPAddress="$2"
        shift
        shift
        ;;
        -hostentry)
        desiredName="$2"
        desiredIPAddress="$3"
        shift
        shift
        shift
        ;;
        *)
        echo "Unknown option: $1"
        exit 1
        ;;
    esac
done

# Configure hostname
if [ -n "$desiredName" ]; then
    currentHostname=$(hostname)
    if [ "$desiredName" != "$currentHostname" ]; then
        hostnamectl set-hostname "$desiredName"
        echo "Hostname updated to: $desiredName"
        log_changes "Hostname updated to: $desiredName"
    else
        [ "$verbose" = true ] && echo "Hostname is already set to: $desiredName"
    fi
fi

# Configure IP address
if [ -n "$desiredIPAddress" ]; then
    currentIPAddress=$(hostname -I | awk '{print $1}')
    if [ "$desiredIPAddress" != "$currentIPAddress" ]; then
        sed -i "/$currentIPAddress/c\\$desiredIPAddress $(hostname) $desiredName" /etc/hosts
        sed -i "s/address: $currentIPAddress/address: $desiredIPAddress/" /etc/netplan/*.yaml
        netplan apply
        echo "IP address updated to: $desiredIPAddress"
        log_changes "IP address updated to: $desiredIPAddress"
    else
        [ "$verbose" = true ] && echo "IP address is already set to: $desiredIPAddress"
    fi
fi

# Configure /etc/hosts entry
if [ -n "$desiredName" ] && [ -n "$desiredIPAddress" ]; then
    if grep -q "$desiredName $desiredIPAddress" /etc/hosts; then
        [ "$verbose" = true ] && echo "Host entry already exists in /etc/hosts"
    else
        echo "$desiredIPAddress $desiredName" >> /etc/hosts
        echo "Added host entry to /etc/hosts: $desiredIPAddress $desiredName"
        log_changes "Added host entry to /etc/hosts: $desiredIPAddress $desiredName"
    fi
fi

exit 0
