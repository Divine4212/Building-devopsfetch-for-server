# DevOpsFetch Script Documentation

## Overview
DevOpsFetch is a Bash script designed to retrieve and display various system information. 
It supports displaying active ports, Docker images and containers, Nginx domains and configurations, user login information, and system activities within a specified date range. 
Additionally, it includes a logging mechanism to track script activities.

## Installation and Configuration
### Prerequisites
Ensure you have `net-tools`, `docker.io`, and `nginx` installed on your system.

### Installation Steps:
1. Clone the Repository
Clone the repository or download the `install.sh` script to your local machine.

2. Run the Installation Script
Execute the `install.sh` script to install dependencies, create the `devopsfetch` script, set up the systemd service, and configure log rotation.

```bash
sudo bash install.sh
or
sudo ./install.sh
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

## Usage
### Command-Line Flags
`-h`, `--help`: Display help and usage information.
`-p`, `--port [port_number]`: Display all active ports and services, or detailed information about a specific port.
`-d`, `--docker [name]`: List all Docker images and containers, or detailed information about a specific container.
`-n`, `--nginx [domain]`: Display all Nginx domains and their ports, or detailed configuration information for a specific domain.
`-u`, `--users [username]`: List all users and their last login times, or detailed information about a specific user.
`-t`, `--time [date_range]`: Display activities within a specified date range (YYYY-MM-DD or YYYY-MM-DD YYYY-MM-DD).

## Examples
### Display Help
```bash
devopsfetch -h
```
### List All Active Ports and Services
```bash
devopsfetch -p
```
### Display Information for a Specific Port
```bash
devopsfetch -p 80
```
### List All Docker Images and Containers
```bash
devopsfetch -d
```
### Display Information for a Specific Container
```bash
devopsfetch -d 'my container'
```
### List All Nginx Domains and Ports
```bash
devopsfetch -n
```
### Display Configuration for a Specific Nginx Domain
```bash
devopsfetch -n example.com
```
### List All Users and Their Last Login Times
```bash
devopsfetch -u
```
### Display Information for a Specific User
```bash
devopsfetch -u username
```
### Display Activities Within a Specified Date Range
```bash
devopsfetch -t 2024-07-22
```
### Display Activities Between Two Dates
```bash
devopsfetch -t 2024-07-22 2024-07-23
```

## Logging Mechanism
The `devopsfetch` script logs its activities to `/var/log/devopsfetch.log`. The log includes timestamps and details of each operation performed by the script.

### Retrieve Logs
