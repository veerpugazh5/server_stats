#!/bin/bash

#===============================================================================
#
#          FILE: server-stats.sh
#
#         USAGE: ./server-stats.sh
#
#   DESCRIPTION: Analyse basic server performance statistics
#
#        AUTHOR: Server Stats Script
#       VERSION: 1.0
#
#===============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print section headers
print_header() {
    echo -e "\n${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to print sub-headers
print_subheader() {
    echo -e "\n${BOLD}${YELLOW}▶ $1${NC}"
}

# Function to create a progress bar
progress_bar() {
    local percent=$1
    local width=40
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    # Choose color based on percentage
    local color=$GREEN
    if [ "$percent" -ge 80 ]; then
        color=$RED
    elif [ "$percent" -ge 60 ]; then
        color=$YELLOW
    fi
    
    printf "${color}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%${NC}" "$percent"
}

#===============================================================================
# MAIN SCRIPT
#===============================================================================

clear
echo -e "${BOLD}${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                        SERVER PERFORMANCE STATS                           ║"
echo "║                     Generated: $(date '+%Y-%m-%d %H:%M:%S')                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

#-------------------------------------------------------------------------------
# SYSTEM INFORMATION (Stretch Goal)
#-------------------------------------------------------------------------------
print_header "SYSTEM INFORMATION"

# Hostname
echo -e "  ${BOLD}Hostname:${NC}        $(hostname)"

# OS Version
if [ -f /etc/os-release ]; then
    os_name=$(grep "^PRETTY_NAME" /etc/os-release | cut -d'"' -f2)
    echo -e "  ${BOLD}OS:${NC}              $os_name"
elif [ -f /etc/redhat-release ]; then
    echo -e "  ${BOLD}OS:${NC}              $(cat /etc/redhat-release)"
else
    echo -e "  ${BOLD}OS:${NC}              $(uname -s) $(uname -r)"
fi

# Kernel Version
echo -e "  ${BOLD}Kernel:${NC}          $(uname -r)"

# Architecture
echo -e "  ${BOLD}Architecture:${NC}    $(uname -m)"

# Uptime
uptime_info=$(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1, $2}')
echo -e "  ${BOLD}Uptime:${NC}          $uptime_info"

# Last Boot
last_boot=$(who -b 2>/dev/null | awk '{print $3, $4}')
echo -e "  ${BOLD}Last Boot:${NC}       $last_boot"

#-------------------------------------------------------------------------------
# LOAD AVERAGE (Stretch Goal)
#-------------------------------------------------------------------------------
print_subheader "Load Average"
load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
cpu_cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)
echo -e "  Load (1m, 5m, 15m): ${BOLD}$load_avg${NC}  |  CPU Cores: ${BOLD}$cpu_cores${NC}"

#-------------------------------------------------------------------------------
# CPU USAGE
#-------------------------------------------------------------------------------
print_header "CPU USAGE"

# Get CPU usage using top (works on most Linux systems)
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d'%' -f1)

# Handle different top output formats
if [ -z "$cpu_idle" ]; then
    cpu_idle=$(top -bn1 | grep "%Cpu" | awk '{print $8}')
fi

# If still empty, try alternative method
if [ -z "$cpu_idle" ]; then
    cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "%.1f", usage}')
else
    cpu_usage=$(echo "100 - $cpu_idle" | bc 2>/dev/null || awk "BEGIN {printf \"%.1f\", 100 - $cpu_idle}")
fi

cpu_usage_int=${cpu_usage%.*}
[ -z "$cpu_usage_int" ] && cpu_usage_int=0

echo -e "  Total CPU Usage: ${BOLD}${cpu_usage}%${NC}"
echo -n "  "
progress_bar "$cpu_usage_int"
echo ""

# CPU breakdown if available
cpu_user=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
cpu_system=$(top -bn1 | grep "Cpu(s)" | awk '{print $4}' | cut -d'%' -f1)
if [ -n "$cpu_user" ] && [ -n "$cpu_system" ]; then
    echo -e "\n  ${BOLD}Breakdown:${NC} User: ${cpu_user}% | System: ${cpu_system}% | Idle: ${cpu_idle}%"
fi

#-------------------------------------------------------------------------------
# MEMORY USAGE
#-------------------------------------------------------------------------------
print_header "MEMORY USAGE"

# Get memory info from /proc/meminfo
mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
mem_buffers=$(grep Buffers /proc/meminfo | awk '{print $2}')
mem_cached=$(grep "^Cached" /proc/meminfo | awk '{print $2}')

# Calculate used memory (Total - Available is more accurate)
if [ -n "$mem_available" ]; then
    mem_used=$((mem_total - mem_available))
else
    # Fallback for older kernels
    mem_used=$((mem_total - mem_free - mem_buffers - mem_cached))
fi

# Calculate percentage
mem_percent=$((mem_used * 100 / mem_total))

# Convert to human readable (MB/GB)
mem_total_mb=$((mem_total / 1024))
mem_used_mb=$((mem_used / 1024))
mem_free_mb=$(((mem_total - mem_used) / 1024))

# Convert to GB if over 1024 MB
if [ $mem_total_mb -ge 1024 ]; then
    mem_total_hr=$(awk "BEGIN {printf \"%.2f GB\", $mem_total_mb/1024}")
    mem_used_hr=$(awk "BEGIN {printf \"%.2f GB\", $mem_used_mb/1024}")
    mem_free_hr=$(awk "BEGIN {printf \"%.2f GB\", $mem_free_mb/1024}")
else
    mem_total_hr="${mem_total_mb} MB"
    mem_used_hr="${mem_used_mb} MB"
    mem_free_hr="${mem_free_mb} MB"
fi

echo -e "  ${BOLD}Total Memory:${NC}    $mem_total_hr"
echo -e "  ${BOLD}Used Memory:${NC}     $mem_used_hr (${mem_percent}%)"
echo -e "  ${BOLD}Free Memory:${NC}     $mem_free_hr ($((100 - mem_percent))%)"
echo -n "  "
progress_bar "$mem_percent"
echo ""

# Swap Usage
print_subheader "Swap Usage"
swap_total=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
swap_free=$(grep SwapFree /proc/meminfo | awk '{print $2}')
swap_used=$((swap_total - swap_free))

if [ "$swap_total" -gt 0 ]; then
    swap_percent=$((swap_used * 100 / swap_total))
    swap_total_mb=$((swap_total / 1024))
    swap_used_mb=$((swap_used / 1024))
    echo -e "  Total: ${swap_total_mb} MB | Used: ${swap_used_mb} MB (${swap_percent}%)"
    echo -n "  "
    progress_bar "$swap_percent"
    echo ""
else
    echo -e "  ${YELLOW}No swap configured${NC}"
fi

#-------------------------------------------------------------------------------
# DISK USAGE
#-------------------------------------------------------------------------------
print_header "DISK USAGE"

# Get disk usage for main partitions (excluding tmpfs, devtmpfs, etc.)
echo -e "  ${BOLD}Filesystem            Size      Used      Free   Use%  Mounted on${NC}"
echo -e "  ${BOLD}─────────────────────────────────────────────────────────────────${NC}"

df -h --output=source,size,used,avail,pcent,target 2>/dev/null | grep -E "^/dev/" | while read -r line; do
    fs=$(echo "$line" | awk '{print $1}')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')
    avail=$(echo "$line" | awk '{print $4}')
    percent=$(echo "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')
    
    # Color based on usage
    if [ "$percent" -ge 90 ]; then
        color=$RED
    elif [ "$percent" -ge 70 ]; then
        color=$YELLOW
    else
        color=$GREEN
    fi
    
    printf "  %-20s %8s %8s %8s ${color}%4s%%${NC}  %s\n" "$fs" "$size" "$used" "$avail" "$percent" "$mount"
done

# Total disk summary
print_subheader "Overall Disk Summary"
total_size=$(df -h --total 2>/dev/null | grep "^total" | awk '{print $2}')
total_used=$(df -h --total 2>/dev/null | grep "^total" | awk '{print $3}')
total_avail=$(df -h --total 2>/dev/null | grep "^total" | awk '{print $4}')
total_percent=$(df -h --total 2>/dev/null | grep "^total" | awk '{print $5}' | tr -d '%')

if [ -n "$total_size" ]; then
    echo -e "  Total: ${BOLD}$total_size${NC} | Used: ${BOLD}$total_used${NC} | Available: ${BOLD}$total_avail${NC}"
    echo -n "  "
    progress_bar "${total_percent:-0}"
    echo ""
fi

#-------------------------------------------------------------------------------
# TOP 5 PROCESSES BY CPU USAGE
#-------------------------------------------------------------------------------
print_header "TOP 5 PROCESSES BY CPU USAGE"

echo -e "  ${BOLD}  PID   CPU%   MEM%   COMMAND${NC}"
echo -e "  ${BOLD}─────────────────────────────────────────────────────────────────${NC}"
ps aux --sort=-%cpu | head -6 | tail -5 | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    cpu=$(echo "$line" | awk '{print $3}')
    mem=$(echo "$line" | awk '{print $4}')
    cmd=$(echo "$line" | awk '{print $11}' | head -c 50)
    printf "  %6s  %5s  %5s   %s\n" "$pid" "$cpu%" "$mem%" "$cmd"
done

#-------------------------------------------------------------------------------
# TOP 5 PROCESSES BY MEMORY USAGE
#-------------------------------------------------------------------------------
print_header "TOP 5 PROCESSES BY MEMORY USAGE"

echo -e "  ${BOLD}  PID   MEM%   CPU%   COMMAND${NC}"
echo -e "  ${BOLD}─────────────────────────────────────────────────────────────────${NC}"
ps aux --sort=-%mem | head -6 | tail -5 | while read -r line; do
    pid=$(echo "$line" | awk '{print $2}')
    cpu=$(echo "$line" | awk '{print $3}')
    mem=$(echo "$line" | awk '{print $4}')
    cmd=$(echo "$line" | awk '{print $11}' | head -c 50)
    printf "  %6s  %5s  %5s   %s\n" "$pid" "$mem%" "$cpu%" "$cmd"
done

#-------------------------------------------------------------------------------
# LOGGED IN USERS (Stretch Goal)
#-------------------------------------------------------------------------------
print_header "LOGGED IN USERS"

user_count=$(who | wc -l)
echo -e "  ${BOLD}Currently logged in:${NC} $user_count user(s)"
echo ""
if [ "$user_count" -gt 0 ]; then
    echo -e "  ${BOLD}USER       TTY      FROM              LOGIN TIME${NC}"
    echo -e "  ${BOLD}─────────────────────────────────────────────────────────────────${NC}"
    who | while read -r line; do
        user=$(echo "$line" | awk '{print $1}')
        tty=$(echo "$line" | awk '{print $2}')
        time=$(echo "$line" | awk '{print $3, $4}')
        from=$(echo "$line" | awk '{print $5}' | tr -d '()')
        printf "  %-10s %-8s %-16s %s\n" "$user" "$tty" "${from:--}" "$time"
    done
fi

#-------------------------------------------------------------------------------
# FAILED LOGIN ATTEMPTS (Stretch Goal)
#-------------------------------------------------------------------------------
print_header "FAILED LOGIN ATTEMPTS"

# Check different log locations
if [ -f /var/log/auth.log ]; then
    failed_attempts=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
    echo -e "  Failed password attempts (auth.log): ${BOLD}${RED}$failed_attempts${NC}"
    
    # Show last 5 failed attempts
    if [ "$failed_attempts" -gt 0 ]; then
        echo -e "\n  ${BOLD}Recent failed attempts:${NC}"
        grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5 | while read -r line; do
            echo "    $(echo "$line" | awk '{print $1, $2, $3}') - $(echo "$line" | grep -oP 'from \K[\d.]+' || echo 'N/A')"
        done
    fi
elif [ -f /var/log/secure ]; then
    failed_attempts=$(grep -c "Failed password" /var/log/secure 2>/dev/null || echo "0")
    echo -e "  Failed password attempts (secure): ${BOLD}${RED}$failed_attempts${NC}"
else
    echo -e "  ${YELLOW}Unable to access authentication logs (requires root privileges)${NC}"
fi

#-------------------------------------------------------------------------------
# NETWORK INFORMATION (Stretch Goal)
#-------------------------------------------------------------------------------
print_header "NETWORK INFORMATION"

# Get primary IP address
primary_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -n "$primary_ip" ]; then
    echo -e "  ${BOLD}Primary IP:${NC}      $primary_ip"
fi

# Get public IP (if curl is available)
if command -v curl &> /dev/null; then
    public_ip=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || echo "N/A")
    if [ "$public_ip" != "N/A" ] && [ -n "$public_ip" ]; then
        echo -e "  ${BOLD}Public IP:${NC}       $public_ip"
    fi
fi

# Network interfaces
print_subheader "Network Interfaces"
ip -br addr 2>/dev/null | grep -v "^lo" | while read -r line; do
    iface=$(echo "$line" | awk '{print $1}')
    state=$(echo "$line" | awk '{print $2}')
    addr=$(echo "$line" | awk '{print $3}')
    
    if [ "$state" = "UP" ]; then
        state_color=$GREEN
    else
        state_color=$RED
    fi
    
    printf "  %-12s ${state_color}%-6s${NC}  %s\n" "$iface" "$state" "${addr:--}"
done

#-------------------------------------------------------------------------------
# SERVICES STATUS (Stretch Goal)
#-------------------------------------------------------------------------------
print_header "IMPORTANT SERVICES STATUS"

# Check common services
services=("sshd" "nginx" "apache2" "httpd" "mysql" "mariadb" "postgresql" "docker" "firewalld" "ufw")

for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        printf "  %-15s ${GREEN}● Running${NC}\n" "$service"
    elif systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
        printf "  %-15s ${RED}○ Stopped${NC}\n" "$service"
    fi
done

#-------------------------------------------------------------------------------
# FOOTER
#-------------------------------------------------------------------------------
echo -e "\n${BOLD}${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                          END OF SERVER STATS                              ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

