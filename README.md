# 🚀 n8n - Workflow Automation Platform

[![n8n](https://img.shields.io/badge/n8n-FF5E5B?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Cloudflare](https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://cloudflare.com)

## 📋 Overview

n8n is a powerful workflow automation platform that helps you automate tasks across different services. This repository provides a complete Docker-based setup for n8n with Cloudflare Tunnel integration for secure remote access.

## 🛠️ Features

- 🔄 Visual workflow builder with drag-and-drop interface
- 🔌 200+ integrations with popular services and APIs
- 🐳 Docker-based deployment for easy setup and management
- 🌐 Cloudflare Tunnel integration for secure remote access
- 🔒 Self-hosted option with full control over your data
- 📱 Mobile-friendly responsive interface
- 🔐 Secure credential management
- 🚀 High performance and scalability
- 🔧 Automated installation script for multiple Linux distributions

## 🚀 Quick Start

### Automated Installation

This repository includes a comprehensive installation script that supports multiple Linux distributions:

```bash
# Download and run the installation script
curl -sSL https://raw.githubusercontent.com/hungnguyen1503/n8n/main/install_n8n.sh | bash
```

The script will automatically:
- ✅ Detect your operating system and architecture
- ✅ Update system packages
- ✅ Install Docker and Docker Compose if not present
- ✅ Create necessary directories with proper permissions
- ✅ Download and configure the docker-compose file
- ✅ Start n8n and Cloudflare Tunnel services
- ✅ Handle existing installations gracefully

### Manual Installation

If you prefer manual installation:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hungnguyen1503/n8n.git
   cd n8n
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   nano .env  # or use your preferred editor
   ```

3. **Start the services:**
   ```bash
   docker-compose up -d
   ```

## 🔧 Configuration

### Environment Setup

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit the `.env` file with your actual values:**
   ```bash
   nano .env  # or use your preferred editor
   ```

3. **Required variables to configure:**
   - `CLOUDFLARE_TUNNEL_TOKEN`: Get from [Cloudflare Dashboard](https://dash.cloudflare.com/cloudflare-one/tunnels)
   - `N8N_EDITOR_BASE_URL`: Your domain or localhost URL
   - `WEBHOOK_URL`: Your webhook base URL
   - `N8N_HOST`: Your domain name

### Environment Variables

Create a `.env` file in the project root with the following variables:

> **⚠️ Security Note:** Never commit your actual `.env` file to version control. Use `.env.example` as a template and keep your real credentials secure.

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `CLOUDFLARE_TUNNEL_TOKEN` | Cloudflare Tunnel token for remote access | - | Yes |
| `N8N_EDITOR_BASE_URL` | Base URL for the n8n editor | - | Yes |
| `WEBHOOK_URL` | Webhook base URL for n8n | - | Yes |
| `N8N_HOST` | Host domain for n8n | - | Yes |

### Docker Compose Services

The setup includes two main services:

#### n8n Service (`svr_n8n`)
- **Image:** `n8nio/n8n:latest`
- **Port:** `5678:5678`
- **Volume:** `./vol_n8n:/home/node/.n8n`
- **Features:**
  - Secure cookie support
  - Configurable timezone
  - Binary data storage on filesystem
  - File permissions enforcement
  - Multiple runners support

#### Cloudflare Tunnel (`cloudflared`)
- **Image:** `cloudflare/cloudflared:latest`
- **Network:** Host mode for optimal performance
- **Features:**
  - Secure remote access
  - Automatic tunnel management
  - DNS optimization (1.1.1.1, 1.0.0.1)

## 📁 Project Structure

```
n8n/
├── docker-compose.yaml    # Docker Compose configuration
├── install_n8n.sh        # Automated installation script
├── README.md             # This file
├── .gitignore           # Git ignore rules
└── vol_n8n/             # n8n data volume (created during installation)
```

## 🌐 Access

After installation, access n8n through:

- **Local access:** http://localhost:5678/
- **Remote access:** Via Cloudflare Tunnel (configured in your tunnel settings)

## 🔧 Management Commands

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f svr_n8n
docker-compose logs -f cloudflared
```

### Update Services
```bash
docker-compose pull
docker-compose up -d
```

### Backup Data
```bash
# Backup n8n data
tar -czf n8n_backup_$(date +%Y%m%d_%H%M%S).tar.gz vol_n8n/
```

## 🛡️ Security Considerations

- **Cloudflare Tunnel:** Provides secure remote access without exposing ports
- **File Permissions:** Enforced settings file permissions for security
- **Secure Cookies:** Configurable secure cookie support
- **Volume Isolation:** n8n data is isolated in dedicated volumes
- **Environment Variables:** Sensitive data is stored in `.env` files (excluded from version control)

### Advanced Security Options

For additional security, consider these encryption methods:

#### Option 1: Docker Secrets (Production)
```bash
# Create encrypted secrets
echo "your_cloudflare_token" | docker secret create cloudflare_tunnel_token -
```

#### Option 2: GPG Encryption
```bash
# Encrypt your .env file
gpg -c .env
# This creates .env.gpg (encrypted) - commit this instead
```

#### Option 3: Ansible Vault
```bash
# Encrypt with Ansible Vault
ansible-vault encrypt .env
# Use: ansible-vault decrypt .env
```

## 📚 Documentation

For detailed n8n documentation, visit:
- [Official n8n Documentation](https://docs.n8n.io)
- [API Reference](https://docs.n8n.io/api/)
- [Community Forum](https://community.n8n.io)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🐛 Troubleshooting

### Common Issues

1. **Port 5678 already in use:**
   ```bash
   sudo lsof -i :5678
   sudo kill -9 <PID>
   ```

2. **Permission issues with vol_n8n:**
   ```bash
   sudo chown -R 1000:1000 vol_n8n/
   sudo chmod -R 755 vol_n8n/
   ```

3. **Docker service not running:**
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

### Logs and Debugging

Check installation logs:
```bash
cat ~/n8n_log_installation.txt
```

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to the [n8n team](https://n8n.io) for creating an amazing workflow automation platform
- Thanks to [Cloudflare](https://cloudflare.com) for providing secure tunnel services
- Thanks to all contributors who have helped improve this setup

## 📞 Support

- [GitHub Issues](https://github.com/n8n-io/n8n/issues)
- [n8n Community Forum](https://community.n8n.io)
- [n8n Discord Server](https://discord.gg/n8n)
- [Cloudflare Support](https://support.cloudflare.com/)

---

Made with ❤️ by the n8n community
