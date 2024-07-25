#!/bin/bash

# Install necessary dependencies
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

show_ports() {
    echo "------------------------------------------------------------------------------------------------"
    echo "| Port | Protocol | Process | Service                                                           |"
    echo "------------------------------------------------------------------------------------------------"
    ss -tuln | awk 'NR>1 {print $5, $1, $7}' | while read line; do
        port=$(echo $line | awk '{print $1}' | sed 's/.*://')
        protocol=$(echo $line | awk '{print $2}')
        process=$(echo $line | awk '{print $3}' | sed 's/,.*//' | sed 's/pid=.*)//')
        service=$(getent services $port | awk '{print $1}')
        printf "| %-5s | %-8s | %-7s | %-64s |\n" "$port" "$protocol" "$process" "$service"
    done
    echo "------------------------------------------------------------------------------------------------"
}

show_nginx() {
    echo "----------------------------------------------------------------------------------------------------------"
    echo "| Server Domain                               | Proxy                    | Configuration File              |"
    echo "----------------------------------------------------------------------------------------------------------"
    grep 'server_name\|proxy_pass' /etc/nginx/sites-available/* | sed 'N;s/\n/ /' | awk '{print $1, $3, $5}' | while read line; do
        config_file=$(echo $line | awk '{print $1}' | sed 's/:.*//')
        server_domain=$(echo $line | awk '{print $3}' | sed 's/;//')
        proxy_pass=$(echo $line | awk '{print $5}' | sed 's/;//')
        printf "| %-40s | %-24s | %-30s |\n" "$server_domain" "$proxy_pass" "$config_file"
    done
    echo "----------------------------------------------------------------------------------------------------------"
}

show_docker() {
    echo "---------------------------------------------------------------------------------"
    echo "| Container ID | Container Name        | Image Name               | Status      |"
    echo "---------------------------------------------------------------------------------"
    sudo docker ps --format "{{.ID}} {{.Names}} {{.Image}} {{.Status}}" | while read line; do
        container_id=$(echo $line | awk '{print $1}')
        container_name=$(echo $line | awk '{print $2}')
        image_name=$(echo $line | awk '{print $3}')
        status=$(echo $line | awk '{print $4, $5, $6, $7, $8}')
        printf "| %-12s | %-20s | %-22s | %-10s |\n" "$container_id" "$container_name" "$image_name" "$status"
    done
    echo "---------------------------------------------------------------------------------"
}

show_users() {
    echo "----------------------------------------------------"
    echo "| Username       | Last Login                      |"
    echo "----------------------------------------------------"
    lastlog | awk 'NR>1 {print $1, $5, $6, $7, $8, $9}' | while read line; do
        username=$(echo $line | awk '{print $1}')
        last_login=$(echo $line | awk '{print $2, $3, $4, $5, $6}')
        printf "| %-14s | %-30s |\n" "$username" "$last_login"
    done
    echo "----------------------------------------------------"
}

show_time_range() {
    start_date=$1
    end_date=$2
    if [ -z "$end_date" ]; then
        end_date=$start_date
    fi
    echo "------------------------------------------------------------------------------------------------"
    echo "| Time                  | Event                                                              |"
    echo "------------------------------------------------------------------------------------------------"
    journalctl --since "$start_date" --until "$end_date" | while read line; do
        time=$(echo $line | awk '{print $1, $2, $3}')
        event=$(echo $line | cut -d' ' -f4-)
        printf "| %-21s | %-64s |\n" "$time" "$event"
    done
    echo "------------------------------------------------------------------------------------------------"
}

show_help() {
    echo "Usage: devopsfetch [OPTION]"
    echo "Options:"
    echo "  -p, --port [port_number]       Display all active ports and services, or detailed information about a specific port."
    echo "  -d, --docker [container_name]  List all Docker images and containers, or detailed information about a specific container."
    echo "  -n, --nginx [domain]           Display all Nginx domains and their ports, or detailed configuration information for a specific domain."
    echo "  -u, --users [username]         List all users and their last login times, or detailed information about a specific user."
    echo "  -t, --time [start_date] [end_date]  Display activities within a specified time range."
    echo "  -h, --help                     Display this help message."
}

case "$1" in
    -p|--port)
        if [ -n "$2" ]; then
            show_ports "$2"
        else
            show_ports
        fi
        ;;
    -d|--docker)
        if [ -n "$2" ]; then
            show_docker "$2"
        else
            show_docker
        fi
        ;;
    -n|--nginx)
        if [ -n "$2" ]; then
            show_nginx "$2"
        else
            show_nginx
        fi
        ;;
    -u|--users)
        if [ -n "$2" ]; then
            show_users "$2"
        else
            show_users
        fi
        ;;
    -t|--time)
        if [ -n "$2" ]; then
            show_time_range "$2" "$3"
        else
            echo "Please provide a start date and optionally an end date in the format YYYY-MM-DD."
        fi
        ;;
    -h|--help)
        show_help
        ;;
    *)
        show_help
        ;;
esac
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/devopsfetch

# Grant sudo privileges to devopsfetch
echo "ALL ALL=(ALL) NOPASSWD: /usr/local/bin/devopsfetch" | sudo tee /etc/sudoers.d/devopsfetch

# Create systemd service
cat << 'EOF' | sudo tee /etc/systemd/system/devopsfetch.service > /dev/null
[Unit]
Description=DevOps Fetch Service
After=network.target

[Service]
ExecStart=/usr/bin/sudo /usr/local/bin/devopsfetch --time $(date +%Y-%m-%d)
StandardOutput=append:/var/log/devopsfetch.log
StandardError=append:/var/log/devopsfetch.log
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemon and enable the service
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

echo "process complete."
