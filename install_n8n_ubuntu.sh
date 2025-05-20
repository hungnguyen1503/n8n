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
                run_command "docker-compose -f n8n-dockercompose.yaml down -f"
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
echo -e "${YELLOW}${START} Checking system updates...${END}${NC}"

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
    log_message "Downloading n8n docker-compose file"
    run_command "sudo wget https://raw.githubusercontent.com/hungnguyen1503/n8n/main/n8n-dockercompose.yaml -O docker-compose.yml"
    export CURR_VOL_DIR=$(pwd)/vol_n8n
    log_message "Starting n8n containers"
    run_command "sudo -E docker-compose up -d"
else
    log_message "Skipping container creation as requested"
    echo -e "${GREEN}${CHECK} Skipped container creation${NC}"
fi

log_message "Installation completed successfully"
echo -e "${GREEN}${CHECK} Installation completed!${NC}"
echo -e "${GREEN}${CHECK} Wait a few minutes and test n8n UI in http://localhost:5678/ your browser${NC}"
echo -e "${GREEN}${CHECK} Installation log saved to: $LOG_FILE${NC}"
