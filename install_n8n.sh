#!/bin/bash

# Icons and colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
CHECK="✅"
WARN="⚠️"
ERROR="❌"
START="🟢"
END="🔴"
INFO="ℹ️"
DOWNLOAD="⬇️"
INSTALL="🛠️"
UPDATE="🔄"
FOLDER="📁"
DOCKER="🐳"
COMPOSE="🧩"
SUCCESS="🟢"
FAILURE="🔴"
USER_ICON="👤"
SYSTEM="🖥️"
NETWORK="🌐"
WAIT="⏳"
FINISH="🏁"
SERVICE="🔧"

# Setup logging
LOG_FILE="$HOME/n8n_log_installation.txt"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

# Function to log messages
log_message() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to run command and log output
run_command() {
    log_message "Executing: $1"
    eval "$1" 2>&1 | while IFS= read -r line; do
        echo "[PROGRESS] $line" >> "$LOG_FILE"
    done
    return ${PIPESTATUS[0]}
}

# Function to setup systemd service
setup_systemd_service() {
    log_message "Setting up systemd service for n8n"
    echo -e "${YELLOW}${START} ${SERVICE} Setting up systemd service...${END}${NC}"
    
    # Check if we're in the n8n directory
    if [ ! -f "n8n.service" ]; then
        log_message "ERROR: n8n.service file not found in current directory"
        echo -e "${RED}${ERROR} n8n.service file not found. Please run this script from the n8n directory.${NC}"
        return 1
    fi
    
    # Copy service file to systemd directory
    log_message "Copying n8n.service to /etc/systemd/system/"
    if run_command "sudo cp n8n.service /etc/systemd/system/"; then
        echo -e "${GREEN}${CHECK} Service file copied successfully${NC}"
    else
        echo -e "${RED}${ERROR} Failed to copy service file${NC}"
        return 1
    fi
    
    # Reload systemd daemon
    log_message "Reloading systemd daemon"
    if run_command "sudo systemctl daemon-reload"; then
        echo -e "${GREEN}${CHECK} Systemd daemon reloaded${NC}"
    else
        echo -e "${RED}${ERROR} Failed to reload systemd daemon${NC}"
        return 1
    fi
    
    # Enable the service
    log_message "Enabling n8n service for auto-start"
    if run_command "sudo systemctl enable n8n.service"; then
        echo -e "${GREEN}${CHECK} Service enabled for auto-start${NC}"
    else
        echo -e "${RED}${ERROR} Failed to enable service${NC}"
        return 1
    fi
    
    # Start the service
    log_message "Starting n8n service"
    if run_command "sudo systemctl start n8n.service"; then
        echo -e "${GREEN}${CHECK} Service started successfully${NC}"
        
        # Wait a moment and check status
        sleep 3
        if run_command "sudo systemctl is-active n8n.service"; then
            echo -e "${GREEN}${CHECK} Service is running and active${NC}"
        else
            echo -e "${YELLOW}${WARN} Service may not be fully started yet${NC}"
        fi
    else
        echo -e "${RED}${ERROR} Failed to start service${NC}"
        return 1
    fi
    
    return 0
}

# Check for existing n8n containers
check_existing_containers() {
    if docker ps -a | grep -q "n8n"; then
        log_message "Found existing n8n containers"
        echo -e "${YELLOW}${WARN} Found existing n8n containers${NC}"
        echo -e "${YELLOW}Please choose an option:${NC}"
        echo "1) Skip container creation and continue with other installations"
        echo "2) Force new installation (WARNING: This will remove existing containers)"
        echo "3) Exit"
        
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            1)
                log_message "User chose to skip container creation"
                echo -e "${GREEN}${CHECK} Skipping container creation${NC}"
                return 1
                ;;
            2)
                log_message "User chose to force new installation"
                echo -e "${YELLOW}${WARN} Removing existing containers...${NC}"
                run_command "docker compose down --volumes --remove-orphans"
                run_command "docker ps -a | grep n8n | awk '{print \$1}' | xargs -r docker rm -f"
                run_command "docker volume prune -f"
                run_command "docker system prune -f"
                run_command "sudo rm -rf ~/vol_n8n"
                run_command "mkdir -p ~/vol_n8n"
                run_command "sudo chown -R 1000:1000 ~/vol_n8n"
                run_command "sudo chmod -R 755 ~/vol_n8n"
                return 0
                ;;
            3)
                log_message "User chose to exit"
                echo -e "${GREEN}${CHECK} Exiting installation${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}${ERROR} Invalid choice${NC}"
                return 1
                ;;
        esac
    fi
    return 0
}

# Check and update system
log_message "Checking system updates"
echo -e "${YELLOW}${START} ${UPDATE} Checking system updates...${END}${NC}"

# Detect package manager
if command -v apt-get &> /dev/null; then
    run_command "sudo apt update"
    run_command "sudo apt upgrade -y"
elif command -v yum &> /dev/null; then
    run_command "sudo yum update -y"
elif command -v dnf &> /dev/null; then
    run_command "sudo dnf update -y"
else
    log_message "WARNING: Could not detect package manager, skipping system update"
    echo -e "${YELLOW}${WARN} Could not detect package manager, skipping system update${NC}"
fi

# Function to detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
        log_message "Detected OS: $OS $VERSION"
    else
        log_message "ERROR: Could not detect OS"
        echo -e "${RED}${ERROR} Could not detect OS${NC}"
        exit 1
    fi
}

# Function to detect architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        "x86_64")
            echo "amd64"
            ;;
        "aarch64"|"arm64")
            echo "arm64"
            ;;
        "armv7l"|"armv6l")
            echo "armhf"
            ;;
        *)
            log_message "ERROR: Unsupported architecture: $ARCH"
            echo -e "${RED}${ERROR} Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac
}

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        log_message "$1 is already installed"
        echo -e "${GREEN}${CHECK} $1 is already installed${NC}"
        return 0
    else
        log_message "$1 is not installed"
        echo -e "${YELLOW}${WARN} $1 is not installed${NC}"
        return 1
    fi
}

# Function to install Docker based on OS
install_docker() {
    ARCH=$(detect_arch)
    log_message "Detected architecture: $ARCH"
    echo -e "${GREEN}${CHECK} Detected architecture: $ARCH${NC}"
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            log_message "Installing Docker for $OS"
            run_command "sudo apt update"
            run_command "sudo apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common"
            run_command "curl -fsSL https://download.docker.com/linux/$([ "$OS" = "Ubuntu" ] && echo "ubuntu" || echo "debian")/gpg | sudo apt-key add -"
            
            if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "armhf" ]; then
                log_message "Configuring ARM architecture repositories"
                if [ "$OS" = "Ubuntu" ]; then
                    run_command "sudo add-apt-repository -y \"deb [arch=$ARCH] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
                else
                    run_command "sudo add-apt-repository -y \"deb [arch=$ARCH] https://download.docker.com/linux/debian $(lsb_release -cs) stable\""
                fi
            else
                log_message "Configuring x86_64 repositories"
                if [ "$OS" = "Ubuntu" ]; then
                    run_command "sudo add-apt-repository -y \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\""
                else
                    run_command "sudo add-apt-repository -y \"deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable\""
                fi
            fi
            
            run_command "sudo apt update"
            run_command "sudo apt install -y docker-ce docker-ce-cli containerd.io"
            ;;
            
        "Raspberry Pi OS")
            log_message "Installing Docker for Raspberry Pi OS"
            run_command "curl -fsSL https://get.docker.com -o get-docker.sh"
            run_command "sudo sh get-docker.sh"
            run_command "sudo usermod -aG docker $USER"
            run_command "rm get-docker.sh"
            ;;
            
        *)
            log_message "ERROR: Unsupported OS: $OS"
            echo -e "${RED}${ERROR} Unsupported OS: $OS${NC}"
            exit 1
            ;;
    esac
    
    log_message "Starting and enabling Docker service"
    run_command "sudo systemctl start docker"
    run_command "sudo systemctl enable docker"
    
    if ! groups $USER | grep -q docker; then
        log_message "Adding user to docker group"
        run_command "sudo usermod -aG docker $USER"
        echo -e "${YELLOW}${WARN} Added user to docker group. Please log out and log back in for changes to take effect.${NC}"
    fi
}

# Function to install Docker Compose
install_docker_compose() {
    log_message "Installing Docker Compose"
    run_command "sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose"
    run_command "sudo chmod +x /usr/local/bin/docker-compose"
}

# Main installation process
log_message "Starting n8n installation process"
echo -e "${YELLOW}${START} Starting installation...${END}${NC}"

detect_os

# Check and install Docker
if ! check_command docker; then
    echo -e "${YELLOW}${START} Installing Docker...${END}${NC}"
    install_docker
    echo -e "${GREEN}${CHECK} Docker installed successfully${NC}"
fi

# Check and install Docker Compose
if ! check_command docker-compose; then
    echo -e "${YELLOW}${START} Installing Docker Compose...${END}${NC}"
    install_docker_compose
    echo -e "${GREEN}${CHECK} Docker Compose installed successfully${NC}"
fi

# Create and setup directory
echo -e "${YELLOW}${START} Creating n8n directory...${END}${NC}"
cd ~
if [ ! -d "vol_n8n" ]; then
    log_message "Creating vol_n8n directory"
    run_command "mkdir vol_n8n"
    run_command "sudo chown -R 1000:1000 vol_n8n"
    run_command "sudo chmod -R 755 vol_n8n"
    echo -e "${GREEN}${CHECK} Created vol_n8n directory${NC}"
else
    log_message "vol_n8n directory already exists"
    echo -e "${GREEN}${CHECK} vol_n8n directory already exists${NC}"
fi

# Setup and start n8n
echo -e "${YELLOW}${START} Starting n8n...${END}${NC}"

# Check for existing containers before proceeding
if check_existing_containers; then
    log_message "Using local docker-compose.yaml file"
    # Check if docker-compose.yaml exists in the n8n directory
    if [ -f "/home/tvbox/n8n/docker-compose.yaml" ]; then
        log_message "Using existing docker-compose.yaml file"
        echo -e "${GREEN}${CHECK} Using existing docker-compose.yaml file${NC}"
    else
        log_message "ERROR: docker-compose.yaml file not found in /home/tvbox/n8n"
        echo -e "${RED}${ERROR} docker-compose.yaml file not found. Please ensure the file exists in the n8n directory.${NC}"
        exit 1
    fi
    
    log_message "Starting n8n containers"
    if run_command "cd /home/tvbox/n8n && docker compose up -d"; then
        log_message "${DOCKER} n8n containers started"
        echo -e "${GREEN}${CHECK} n8n containers started successfully${NC}"
    else
        log_message "ERROR: Failed to start n8n containers"
        echo -e "${RED}${ERROR} Failed to start n8n containers${NC}"
        exit 1
    fi
else
    log_message "Skipping container creation as requested"
    echo -e "${GREEN}${CHECK} Skipped container creation${NC}"
fi

# Change back to n8n directory for systemd service setup
cd /home/tvbox/n8n

# Setup systemd service
echo -e "${YELLOW}${START} ${SERVICE} Setting up systemd service...${END}${NC}"
if setup_systemd_service; then
    echo -e "${GREEN}${CHECK} Systemd service setup completed successfully${NC}"
else
    echo -e "${YELLOW}${WARN} Systemd service setup failed, but n8n is still running${NC}"
    echo -e "${YELLOW}${WARN} You can manually set up the service later using the n8n.service file${NC}"
fi

log_message "Installation completed successfully"
echo -e "${GREEN}${CHECK} ${FINISH} Installation completed!${NC}"
echo -e "${GREEN}${CHECK} ${WAIT} Wait a few minutes and test n8n UI in http://localhost:5678/ your browser${NC}"
echo -e "${GREEN}${CHECK} ${INFO} Installation log saved to: $LOG_FILE${NC}"

# Display service management information
echo -e "${GREEN}${CHECK} ${SERVICE} Systemd service has been set up!${NC}"
echo -e "${GREEN}${CHECK} n8n will now automatically start on every system reboot${NC}"
echo -e "${GREEN}${CHECK} Service management commands:${NC}"
echo -e "${INFO}   Check status: sudo systemctl status n8n.service${NC}"
echo -e "${INFO}   View logs: sudo journalctl -u n8n.service -f${NC}"
echo -e "${INFO}   Restart: sudo systemctl restart n8n.service${NC}"
echo -e "${INFO}   Stop: sudo systemctl stop n8n.service${NC}"
echo -e "${INFO}   Disable auto-start: sudo systemctl disable n8n.service${NC}"

echo -e "${GREEN}${CHECK} ${FINISH} Installation Summary:${NC}"
echo -e "${INFO}   ✅ Docker and Docker Compose installed/verified${NC}"
echo -e "${INFO}   ✅ n8n containers started and running${NC}"
echo -e "${INFO}   ✅ Systemd service configured for auto-start${NC}"
echo -e "${INFO}   ✅ n8n accessible at: http://localhost:5678/${NC}"
echo -e "${INFO}   📝 Installation log: $LOG_FILE${NC}"
