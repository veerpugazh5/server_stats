# Server Stats

A bash script to analyze and display basic server performance statistics on Linux systems.

## Features

### Core Statistics
- **CPU Usage** - Total CPU usage with visual progress bar and breakdown (user/system/idle)
- **Memory Usage** - Total, used, and free memory with percentages
- **Disk Usage** - Per-filesystem breakdown with color-coded warnings
- **Top 5 CPU Processes** - Processes consuming the most CPU
- **Top 5 Memory Processes** - Processes consuming the most memory

### Additional Statistics
- **System Information** - Hostname, OS version, kernel, architecture
- **Uptime** - System uptime and last boot time
- **Load Average** - 1min, 5min, 15min load averages
- **Swap Usage** - Swap memory statistics
- **Logged In Users** - Current user sessions
- **Failed Login Attempts** - Count of failed SSH attempts
- **Network Information** - IP addresses and interface status
- **Services Status** - Status of common services (SSH, nginx, Apache, MySQL, Docker, etc.)


## Installation

```bash
# Clone the repository
git clone https://github.com/veerpugazh5/server_stats.git
cd server_stats

# Make the script executable
chmod +x server-stats.sh
```

## Usage

```bash
# Run the script
./server-stats.sh

# Run with sudo for full access to system logs
sudo ./server-stats.sh
```

