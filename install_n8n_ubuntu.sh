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

# Function to check if command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}${CHECK} $1 is already installed${NC}"
        return 0
    else
        echo -e "${YELLOW}${WARN} $1 is not installed${NC}"
        return 1
    fi
}

# Check Docker
if ! check_command docker; then
    echo -e "${YELLOW}${START} Start install docker ${END}${NC}"
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
    apt-cache policy docker-ce
    sudo apt install -y docker-ce
    echo -e "${GREEN}${CHECK} Docker installed successfully${NC}"
fi

# Check Docker Compose
if ! check_command docker-compose; then
    echo -e "${YELLOW}${START} Installing Docker Compose ${END}${NC}"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}${CHECK} Docker Compose installed successfully${NC}"
fi

# Create and setup directory
echo -e "${YELLOW}${START} Start creating folder ${END}${NC}"
cd ~
if [ ! -d "vol_n8n" ]; then
    mkdir vol_n8n
    sudo chown -R 1000:1000 vol_n8n
    sudo chmod -R 755 vol_n8n
    echo -e "${GREEN}${CHECK} Created vol_n8n directory${NC}"
else
    echo -e "${GREEN}${CHECK} vol_n8n directory already exists${NC}"
fi

# Setup and start n8n
echo -e "${YELLOW}${START} Start docker compose up ${END}${NC}"
cd vol_n8n
wget https://raw.githubusercontent.com/hungnguyen1503/n8n/main/n8n-dockercompose.yaml -O docker-compose.yml
export CURR_DIR=$(pwd)
sudo -E docker-compose up -d

echo -e "${GREEN}${CHECK} Installation completed!${NC}"
echo -e "${GREEN}${CHECK} Wait a few minutes and test n8n UI in http://localhost:5678/ your browser${NC}"
