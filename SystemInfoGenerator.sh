#!/bin/bash

#Gather system information
Username = $(whoami)
Date = $(date +"%Y%m%d %H:%M:%S")
Hostname=$(hostname)
Distro=$(lsb_release -d | cut -f2)
Uptime=$(uptime -p)

#Hardware
CPU=$(lscpu | grep "Model name" | awk -F ":" '{print $2}' | sed 's/^ *//')
CPUSpeed=$(lscpu | grep "CPU MHz" | awk -F ":" '{print $2}' | sed 's/^ *//')
CPUMaxSpeed=$(lscpu |grep "CPU max MHz" | awk -F ":" '{print $2}' | sed 's/^ *//')
RAM=$(free -h | awk '/^Mem:/ {print $2}')
Disks=$(lsblk -io NAME,MODEL,SIZE |awk '{if (NR>1) print $1,$2,$3}')
Video=$(lspci | grep VGA | awk -F ": " '{print $3}')

#Network Info
FQDN=$(hostname -f)
HostIP=$(hostname -I)
Gateway=$(ip route | awk '/default/ {print $3}')
DNSServer=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}')

#System Status
Users=$(who | awk '{print $1}' | sort | uniq | tr '\n' ',')
DiskSpace=$(df -h --output=source,size |awk 'NR>1 {print $1,$2}')
ProcessCount=$(ps -ef |wc - l)
LoadAvg=$(cat /proc/loadavg |awk '{print $1,$2,$3}')
Memory=$(free -m | awk '/Mem:/ {print $3}')
NetworkPorts=$(netstat -tuln |awk '/tcp/ {print $4}' |cut -d ":" -f2 |sort -n | uniq | tr '\n' ',')
UFWRules=$(ufw status | grep -v "Status:")

#Output
echo ""
echo "System Report generated by $Username, $Date"
echo ""
echo "System Information"
echo "------------------"
echo "Hostname: $Hostname"
echo "OS: $Distro"
echo "Uptime: $Uptime"
echo ""
echo "Hardware Information"
echo "--------------------"
echo "CPU: $CPU"
echo "Speed: $CPUSpeed MHz (Max: $CPUMaxSpeed MHz)"
echo "Ram: $RAM"
echo "Disk: $Disks"
echo "Video: $Video"
echo ""
echo "Network Information"
echo "-------------------"
echo "FQDN: $FQDN"
echo "Host Address: $HostIP"
echo "Gateway IP: $Gateway"
echo "DNS Server: $DNSServer"
echo ""
echo "System Status"
echo "-------------"
echo "Users Logged In: $Users"
echo "Disk space: $DiskSpace"
echo "Process Count: $ProcessCount"
echo "Load Average: $LoadAvg"
echo "Memory Allocation: $Memory MB"
echo "Listening Network Ports: $NetworksPorts"
echo "UFW Rules: $UFWRules"
echo ""
