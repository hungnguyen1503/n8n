# 🚀 n8n - Workflow Automation Platform

[![n8n](https://img.shields.io/badge/n8n-FF5E5B?style=for-the-badge&logo=n8n&logoColor=white)](https://n8n.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)

## 📋 Overview

n8n is a powerful workflow automation platform that helps you automate tasks across different services. It's an open-source tool that allows you to create complex workflows using a visual interface.

## 🛠️ Features

- 🔄 Visual workflow builder
- 🔌 200+ integrations with popular services
- 🔒 Self-hosted option
- 📱 Mobile-friendly interface
- 🔐 Secure credential management
- 🚀 High performance and scalability

## 🚀 Quick Start

### Ubuntu Installation

This repository includes an automated installation script for Ubuntu that handles all the setup process:

```bash
# Download and run the installation script
curl -sSL https://raw.githubusercontent.com/hungnguyen1503/n8n/main/install_n8n_ubuntu.sh | bash
```

The script will:
- ✅ Check and install Docker if not present
- ✅ Check and install Docker Compose if not present
- ✅ Create necessary directories with proper permissions
- ✅ Download and configure the docker-compose file
- ✅ Start n8n automatically

After installation, access n8n at: http://localhost:5678/

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_SECURE_COOKIE` | Enable secure cookies | false |
| `GENERIC_TIMEZONE` | Server timezone | Asia/Ho_Chi_Minh |
| `N8N_EDITOR_BASE_URL` | Base URL for the editor | https://n8n.hungngquang.xyz/ |
| `WEBHOOK_URL` | Webhook base URL | https://n8n.hungngquang.xyz/ |
| `N8N_DEFAULT_BINARY_DATA_MODE` | Binary data storage mode | filesystem |
| `N8N_HOST` | Host domain | n8n.hungngquang.xyz |
| `N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS` | Enforce file permissions | true |

## 📚 Documentation

For detailed documentation, visit:
- [Official Documentation](https://docs.n8n.io)
- [API Reference](https://docs.n8n.io/api/)
- [Community Forum](https://community.n8n.io)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Thanks to all the contributors who have helped make n8n better
- Special thanks to the n8n team for creating such an amazing tool

## 📞 Support

- [GitHub Issues](https://github.com/n8n-io/n8n/issues)
- [Community Forum](https://community.n8n.io)
- [Discord Server](https://discord.gg/n8n)

---

Made with ❤️ by the n8n community
