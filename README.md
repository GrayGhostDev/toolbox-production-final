# Toolbox-Production-Final

A production-ready enterprise toolbox application with comprehensive automation, authentication, and integration features.

## Features

- **Stytch Authentication**: Enterprise-grade authentication with MFA, SSO, and RBAC
- **Background Agents**: Automated development assistants for code quality, documentation, and bug detection
- **MCP Servers**: 12+ integrated Model Context Protocol servers for enhanced capabilities
- **PostgreSQL Database**: Production-ready database with migrations and backups
- **Slack Integration**: Real-time notifications and team collaboration
- **GitHub Integration**: CI/CD automation and repository management
- **TablePlus Support**: Professional database management interface

## Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 16+
- Docker (for containerized services)
- TablePlus (for database management)
- Cursor IDE with --enable-proposed-api flag

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/gray-ghost-data/toolbox-production-final.git
   cd toolbox-production-final
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up databases**
   ```bash
   bash .cursor/scripts/init-database.sh
   ```

4. **Configure environment variables**
   ```bash
   cp .cursor/.env.example .cursor/.env.development
   # Edit .cursor/.env.development with your credentials
   ```

5. **Start the application**
   ```bash
   npm run dev
   ```

6. **Open in Cursor IDE**
   ```bash
   cursor --enable-proposed-api .
   ```

## Project Structure

```
toolbox-production-final/
├── .cursor/                 # Cursor IDE configuration
│   ├── mcp.json            # MCP servers configuration
│   ├── settings.json       # IDE settings
│   ├── scripts/            # Automation scripts
│   └── .env.development    # Development environment
├── src/                    # Source code
│   ├── api/               # API endpoints
│   ├── components/        # React components
│   ├── lib/              # Utility libraries
│   ├── pages/            # Application pages
│   └── services/         # Business logic
├── tests/                 # Test suites
├── docs/                  # Documentation
└── .cursorrules          # Project automation rules
```

## Database Schema

The application uses PostgreSQL with the following databases:
- `toolbox_development` - Development environment
- `toolbox_test` - Test environment
- `toolbox_production` - Production environment

## MCP Servers

Configured Model Context Protocol servers:
- filesystem - File system operations
- git - Version control integration
- postgres - Database operations
- github - GitHub API integration
- memory - Persistent memory storage
- sequential-thinking - Advanced reasoning
- stytch - Authentication services
- slack - Team communication
- docker - Container management
- kubernetes - Orchestration
- puppeteer - Browser automation
- claude-desktop - IDE integration

## Environment Variables

Key environment variables (see `.cursor/.env.example`):
- `STYTCH_PROJECT_ID` - Stytch project identifier
- `STYTCH_SECRET` - Stytch API secret
- `DATABASE_URL` - PostgreSQL connection string
- `GITHUB_TOKEN` - GitHub personal access token
- `SLACK_WEBHOOK_URL` - Slack notification webhook

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run test` - Run test suite
- `npm run lint` - Lint code
- `npm run format` - Format code
- `bash .cursor/scripts/backup-restore.sh backup` - Backup databases
- `bash .cursor/scripts/verify-mcp-servers.sh` - Verify MCP servers

## Authentication

The application uses Stytch for authentication with support for:
- Magic Links
- OAuth (Google, GitHub, Microsoft, GitLab)
- SMS/WhatsApp OTP
- Email OTP
- Passkeys
- TOTP (Time-based One-Time Passwords)
- Multi-Factor Authentication (MFA)
- Single Sign-On (SSO)
- Role-Based Access Control (RBAC)

## Background Agents

Automated agents that enhance development:
- **Dev Assistant**: Code analysis and optimization
- **Quality Bot**: Linting, formatting, and type checking
- **Doc Bot**: Documentation generation and updates
- **BugBot**: Bug detection and security scanning

## CI/CD

GitHub Actions workflow includes:
- Authentication verification
- Code quality checks
- Security scanning
- Automated testing
- Database validation
- MCP server validation
- Slack notifications
- Deployment automation

## Backup and Recovery

```bash
# Create full backup
bash .cursor/scripts/backup-restore.sh backup

# List available backups
bash .cursor/scripts/backup-restore.sh list

# Restore from backup
bash .cursor/scripts/backup-restore.sh restore --file <backup_file>

# Clean old backups
bash .cursor/scripts/backup-restore.sh clean
```

## Security

- All credentials stored in environment files (never committed)
- SSL/TLS encryption for all connections
- Stytch authentication with MFA enforcement
- Regular security scanning with Snyk and GitLeaks
- Audit logging for all critical operations
- GDPR, SOC2, CCPA, HIPAA compliance ready

## Support

For issues, questions, or contributions:
- GitHub Issues: [toolbox-production-final/issues](https://github.com/gray-ghost-data/toolbox-production-final/issues)
- Slack: #toolbox-support
- Documentation: [docs/](./docs/)

## License

Proprietary - Gray Ghost Data

---

Built with Cursor IDE automation system v2025.2