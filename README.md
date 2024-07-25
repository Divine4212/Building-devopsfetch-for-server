# DevOpsFetch Script Documentation

## Overview
DevOpsFetch is a Bash script designed to retrieve and display various system information. 
It supports displaying active ports, Docker images and containers, Nginx domains and configurations, user login information, and system activities within a specified date range. 
Additionally, it includes a logging mechanism to track script activities.

## Installation and Configuration
### Prerequisites
Ensure you have `iproute2`, `docker.io`, and `nginx` installed on your system.

### Installation Steps:
1. Clone the Repository
Clone the repository using the git clone command to your server.

`git clone https://github.com/Divine4212/Building-devopsfetch-for-server.git`

3. Run the Installation Script
`cd` into the file path and execute the `devopsfetch.sh` script to install dependencies, create the `devopsfetch` script, set up the systemd service, and configure log rotation.

```bash
cd Building-devopsfetch-for-server

sudo bash devopsfetch.sh
or
sudo ./devopsfetch.sh
```
3. Verify Installation
Ensure that the `devopsfetch` script is installed correctly and has executable permissions.

```bash
ls -l /usr/local/bin/devopfetch
```

4. Start the Service
Enable and start the `devopsfetch` service

```bash
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service
```

### Configuration
The `devopsfetch` script and systemd service are configured during installation. The log file is located at `/var/log/devopsfetch.log`. Log rotation is set up to manage log files effectively.

## How to Use devopsfetch
### Command-Line Flags
`-h`, `--help`: Display help and usage information.
`-p`, `--port [port_number]`: Display all active ports and services, or detailed information about a specific port.
`-d`, `--docker [name]`: List all Docker images and containers, or detailed information about a specific container.
`-n`, `--nginx [domain]`: Display all Nginx domains and their ports, or detailed configuration information for a specific domain.
`-u`, `--users [username]`: List all users and their last login times, or detailed information about a specific user.
`-t`, `--time [date_range]`: Display activities within a specified date range (YYYY-MM-DD or YYYY-MM-DD YYYY-MM-DD).

## Examples:
### 1. Display Help
```bash
devopsfetch -h
```
### 2. List All Active Ports and Services
```bash
devopsfetch -p
```
### 3. Display Information for a Specific Port
```bash
devopsfetch -p 8080
```
### 4. List All Docker Images and Containers
```bash
devopsfetch -d
```
### 5. Display Information for a Specific Container
```bash
devopsfetch -d 'container'
```
### 6. List All Nginx Domains and Ports
```bash
devopsfetch -n
```
### 7. Display Configuration for a Specific Nginx Domain
```bash
devopsfetch -n 'devops.com'
```
### 8. List All Users and Their Last Login Times
```bash
devopsfetch -u
```
### 9. Display Information for a Specific User
```bash
devopsfetch -u 'user'
```
### 10. Display Activities Within a Specified Date Range
```bash
devopsfetch -t 2024-07-23
```
### 11. Display Activities Between Two Dates
```bash
devopsfetch -t 2024-06-20 2024-07-23
```

## Logging Mechanism
The `devopsfetch` script logs its activities to `/var/log/devopsfetch.log`. The log includes timestamps and details of each operation performed by the script.

### Retrieve Logs
1. View Logs
Use `cat`, `less`, or `tail` to view the log file.
```bash
sudo cat /var/log/devopsfetch.log
```
2. Follow Logs in Real-Time
Use `tail` with the `-f` option to follow the log file in real-time.
```bash
sudo tail -f /var/log/devopsfetch.log
```

## Log Rotation
The log rotation configuration ensures that the log file is rotated daily, with a maximum of 7 rotated logs kept. The logs are compressed to save space. The log rotation configuration is located at `/etc/logrotate.d/devopsfetch`.

### Log Rotation Configuration
```bash
/var/log/devopsfetch.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0640 root utmp
    sharedscripts
    postrotate
        systemctl reload devopsfetch.service > /dev/null 2>&1 || true
    endscript
}
```
This configuration ensures that the log file does not grow indefinitely and old logs are properly managed.

## Conclusion
The `devopsfetch` script provides a comprehensive way to monitor and retrieve various system information. With easy installation, configurable logging, and support for multiple information retrieval options, it is a valuable tool for system administrators and DevOps engineers.
