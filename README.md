# Devopsfetch Initialization

This command line tool called `devopsfetch` is a command-line tool designed for quick retrieval and display of critical system information. It provides easy access to details about ports, Docker containers, Nginx configurations, user logins, and system activities within a time ranges.

## Features
1. Display active ports and services
2. List Docker images and containers
3. Show Nginx domain configurations
4. View user login information
5. Monitor system activities within specified time ranges
6. Monitoring with systemd

## Installation

1. Clone Repository and cd into the cloned directory.
``` bash
git clone https://github.com/Divine4212/Building-devopsfetch-for-server.git
cd Building-devopsfetch-for-server.git
```

2. Make the `devopsfetch_install.sh` executable
```bash
chmod +x devopsfetch_install.sh
```

3. Run `devopsfetch_install.sh` as Root
```bash
sudo ./devopsfetch_install.sh
```
4. View help
```bash
devopsfetch -h
```
5. View User
```bash
devopsfetch -u
```
6. View Ports
```bash
devopsfetch -p
```
7. Display info about specific port
```bash
devopsfetch -p 8080
``` 
9. View docker containers
```bash
devopsfetch -d
```
10. Get info about specific docker container
```bash
devopsfetch -p container_name
```
11. Display activities
```bash
devopsfetch -t now now
```

## Installation Process

1. Update system package list

2. Install dependencies
`nginx`, `docker.io`, `jq`, `iproute2`

4. The `main` devopsfetch script is now copied to `/usr/local/bin/`, in order to make it accessible system-wide.

5. Appropriate permissions are set to make script executable.

6. A systemd service file is created `(/etc/systemd/system/devopsfetch.service)` to run script periodically.

7. A `daemon-reload` followed by `Enable` and then `start` systemd service is executed

8. log rotation for the `devopsfetch` logs is set.

After the installation script runs, `devopsfetch` will be installed as a command and the systemd service is set up to collect and log system information periodically. Also set root priviledges for the `devopsfetch_install.sh`
