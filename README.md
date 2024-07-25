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
`cd` into the file path and execute the `install.sh` script to install dependencies, create the `devopsfetch` script, set up the systemd service, and configure log rotation.

```bash
cd devopsfetch
sudo bash devopsfetch.sh
or
sudo ./devopsfetch.sh
```
### Install.sh file
```bash
#!/bin/bash

# Install dependencies
sudo apt update
sudo apt install -y iproute2 docker.io nginx

# Add /usr/local/bin to PATH in .bashrc
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc

# Create the devopsfetch script with sudo
sudo tee /usr/local/bin/devopsfetch > /dev/null << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/devopsfetch.log"

log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

show_help() {
    log_message "Displaying help"
    cat << HELP
Usage: ${0##*/} [-h] [-p [port_number]] [-d [container_name]] [-n [domain]] [-u [username]] [-t [date_range]]
Retrieve and display system information.

    -h, --help              Display this help and exit.
    -p, --port [port_number]Display all active ports and services, or detailed information about a specific port.
    -d, --docker [name]     List all Docker images and containers, or detailed information about a specific container.
    -n, --nginx [domain]    Display all Nginx domains and their ports, or detailed configuration information for a specific domain.
    -u, --users [username]  List all users and their last login times, or detailed information about a specific user.
    -t, --time [date_range] Display activities within a specified date range (YYYY-MM-DD or YYYY-MM-DD YYYY-MM-DD).
HELP
}

list_ports() {
    log_message "Listing all active ports and services"
    echo -e "Proto\tRecv-Q\tSend-Q\tLocal Address\t\tForeign Address\t\tState\tPID/Program name"
    netstat -tulnp | awk 'NR>2 {print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7}'
}

port_info() {
    local port=$1
    log_message "Displaying information for port $port"
    echo -e "Information for Port $port:"
    netstat -tulnp | grep ":$port " | awk '{print $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7}'
}

list_docker() {
    log_message "Listing all Docker images and containers"
    echo "Docker Images:"
    sudo docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ImageID}}\t{{.CreatedAt}}\t{{.Size}}"
    echo "Docker Containers:"
    sudo docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.ID}}\t{{.Status}}\t{{.Ports}}"
}

docker_info() {
    local name=$1
    log_message "Displaying information for Docker container $name"
    echo "Information for Docker Container $name:"
    sudo docker inspect $name
}

list_nginx() {
    log_message "Listing all Nginx domains and their ports"
    echo -e "Domain\t\t\t\tPort"
    sudo nginx -T | awk '/server_name/ {getline; domain=$2} /listen/ {port=$2; print domain "\t" port}'
}

nginx_info() {
    local domain=$1
    log_message "Displaying configuration for Nginx domain $domain"
    echo "Configuration for Nginx Domain $domain:"
    sudo nginx -T | awk -v domain="$domain" '
        $0 ~ "server_name " domain {show=1}
        show {print}
        $0 ~ "}" && show {show=0}'
}

list_users() {
    log_message "Listing all users and their last login times"
    echo "Users and Last Login Times:"
    lastlog | awk 'NR>1 {print $1 "\t" $3 "\t" $4 "\t" $5 " " $6 " " $7 " " $8}'
}

user_info() {
    local user=$1
    log_message "Displaying information for user $user"
    echo "Information for User $user:"
    lastlog -u $1 | awk 'NR>1 {print $1 "\t" $3 "\t" $4 "\t" $5 " " $6 " " $7 " " $8}'
}

time_range_activities() {
    local start_date="$1"
    local end_date="$2"
    log_message "Displaying activities from $start_date to $end_date"
    echo "Activities from $start_date to $end_date:"
    journalctl --since="$start_date" --until="$end_date"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--port)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                port_info $2
                shift
            else
                list_ports
            fi
            ;;
        -d|--docker)
            if [[ -n "$2" ]]; then
                docker_info $2
                shift
            else
                list_docker
            fi
            ;;
        -n|--nginx)
            if [[ -n "$2" ]]; then
                nginx_info $2
                shift
            else
                list_nginx
            fi
            ;;
        -u|--users)
            if [[ -n "$2" ]]; then
                user_info $2
                shift
            else
                list_users
            fi
            ;;
        -t|--time)
            if [[ -n "$2" ]]; then
                if [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && -z "$3" ]]; then
                    log_message "Activities on $2"
                    echo "Activities on $2:"
                    time_range_activities "$2" "$2"
                    shift 2
                elif [[ "$2" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ && "$3" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                    log_message "Activities from $2 to $3"
                    echo "Activities from $2 to $3:"
                    time_range_activities "$2" "$3"
                    shift 3
                else
                    log_message "Invalid date range format. Use YYYY-MM-DD or YYYY-MM-DD YYYY-MM-DD."
                    echo "Invalid date range format. Use YYYY-MM-DD or YYYY-MM-DD YYYY-MM-DD."
                    exit 1
                fi
            else
                current_date=$(date +'%Y-%m-%d')
                log_message "No date provided, using current date: $current_date"
                echo "Activities on $current_date:"
                time_range_activities "$current_date" "$current_date"
                shift
            fi
            ;;
        *)
            log_message "Unknown parameter passed: $1"
            echo "Unknown parameter passed: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/devopsfetch

# Grant sudo privileges to devopsfetch
echo "ALL ALL=(ALL) NOPASSWD: /usr/local/bin/devopsfetch" | sudo tee /etc/sudoers.d/devopsfetch

# Create systemd service file
cat << 'EOF' | sudo tee /etc/systemd/system/devopsfetch.service > /dev/null
[Unit]
Description=DevOps Fetch Service
After=network.target

[Service]
ExecStart=/usr/bin/sudo /usr/local/bin/devopsfetch
StandardOutput=append:/var/log/devopsfetch.log
StandardError=append:/var/log/devopsfetch.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable devopsfetch.service
sudo systemctl start devopsfetch.service

# Setup log rotation
cat << 'EOF' | sudo tee /etc/logrotate.d/devopsfetch > /dev/null
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
EOF

echo "Process Complete."
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
