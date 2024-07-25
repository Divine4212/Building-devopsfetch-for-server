#!/bin/bash

# Install dependencies
sudo apt update
sudo apt install -y net-tools docker.io nginx

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
    printf "%-10s %-8s %-8s %-22s %-22s %-12s %-20s\n" "Proto" "Recv-Q" "Send-Q" "Local Address" "Foreign Address" "State" "PID/Program name"
    netstat -tulnp | awk 'NR>2 {printf "%-10s %-8s %-8s %-22s %-22s %-12s %-20s\n", $1, $2, $3, $4, $5, $6, $7}'
}

port_info() {
    local port=$1
    log_message "Displaying information for port $port"
    printf "%-10s %-8s %-8s %-22s %-22s %-12s %-20s\n" "Proto" "Recv-Q" "Send-Q" "Local Address" "Foreign Address" "State" "PID/Program name"
    netstat -tulnp | grep ":$port " | awk '{printf "%-10s %-8s %-8s %-22s %-22s %-12s %-20s\n", $1, $2, $3, $4, $5, $6, $7}'
}

list_docker() {
    log_message "Listing all Docker images and containers"
    echo "Docker Images:"
    printf "%-20s %-10s %-20s %-30s %-10s\n" "Repository" "Tag" "ImageID" "CreatedAt" "Size"
    sudo docker images --format "{{.Repository}}\t{{.Tag}}\t{{.ImageID}}\t{{.CreatedAt}}\t{{.Size}}" | column -t
    echo "Docker Containers:"
    printf "%-20s %-30s %-20s %-20s %-30s\n" "Names" "Image" "ID" "Status" "Ports"
    sudo docker ps -a --format "{{.Names}}\t{{.Image}}\t{{.ID}}\t{{.Status}}\t{{.Ports}}" | column -t
}

docker_info() {
    local name=$1
    log_message "Displaying information for Docker container $name"
    echo "Information for Docker Container $name:"
    sudo docker inspect $name
}

list_nginx() {
    log_message "Listing all Nginx domains and their ports"
    printf "%-30s %-10s\n" "Domain" "Port"
    sudo nginx -T 2>/dev/null | awk '
        $1 == "server_name" {domain = $2}
        $1 == "listen" {print domain, $2}
    ' | column -t
}

nginx_info() {
    local domain=$1
    log_message "Displaying configuration for Nginx domain $domain"
    echo "Configuration for Nginx Domain $domain:"
    sudo nginx -T 2>/dev/null | awk -v domain="$domain" '
        $0 ~ "server_name " domain {show=1}
        show {print}
        $0 ~ "}" && show {show=0}'
}

list_users() {
    log_message "Listing all users and their last login times"
    printf "%-20s %-20s %-30s\n" "Username" "Last Login Time" "From"
    lastlog | awk 'NR>1 {printf "%-20s %-20s %-30s\n", $1, $4" "$5" "$6" "$7, $3}'
}

user_info() {
    local user=$1
    log_message "Displaying information for user $user"
    printf "%-20s %-20s %-30s\n" "Username" "Last Login Time" "From"
    lastlog -u $user | awk 'NR>1 {printf "%-20s %-20s %-30s\n", $1, $4" "$5" "$6" "$7, $3}'
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
