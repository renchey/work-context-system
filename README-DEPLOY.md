# Deployment Guide - Work Context System

This guide covers deployment strategies for the Work Context System across various platforms and environments.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [GitHub Codespaces](#github-codespaces)
- [Production Deployment](#production-deployment)
- [Environment Configuration](#environment-configuration)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)

## Prerequisites

### Required Tools
- Node.js 18.x or 20.x
- npm 9.x or higher
- Git
- GitHub CLI (optional but recommended)

### Required Accounts
- GitHub account with repository access
- Vercel account (for production deployment)
- (Optional) Cloud provider account (AWS, GCP, Azure)

## Local Development

### Quick Start
```bash
# Clone the repository
git clone <repository-url>
cd work-context-system

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

### Development Commands
```bash
npm run dev        # Start development server
npm run build      # Build for production
npm run test       # Run test suite
npm run lint       # Run linter
npm run type-check # TypeScript type checking
```

## GitHub Codespaces

### Setup
1. Navigate to the repository on GitHub
2. Click "Code" → "Codespaces" → "Create codespace on main"
3. Wait for the devcontainer to initialize (automatic via `.devcontainer/devcontainer.json`)
4. The environment will automatically:
   - Install all dependencies
   - Configure VS Code extensions
   - Set up port forwarding

### Codespaces Configuration
The project uses a TypeScript devcontainer configuration with:
- Node.js 20
- TypeScript tooling
- ESLint and Prettier
- GitHub Copilot integration

## Production Deployment

### Vercel (Recommended)

#### One-Click Deploy
[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=<your-repo-url>)

#### Manual Deployment
```bash
# Install Vercel CLI
npm i -g vercel

# Login to Vercel
vercel login

# Deploy to production
vercel --prod
```

#### GitHub Integration
1. Connect repository to Vercel
2. Configure environment variables in Vercel dashboard
3. Enable automatic deployments for `main` branch
4. Pull requests will get preview deployments automatically

### Docker Deployment

```bash
# Build Docker image
docker build -t work-context-system .

# Run container
docker run -p 3000:3000 \
  -e NODE_ENV=production \
  work-context-system
```

### Kubernetes Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: work-context-system
spec:
  replicas: 3
  selector:
    matchLabels:
      app: work-context-system
  template:
    metadata:
      labels:
        app: work-context-system
    spec:
      containers:
      - name: app
        image: work-context-system:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
```

```bash
# Apply configuration
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

## Environment Configuration

### Environment Variables

Create a `.env` file in the project root:

```env
# Application
NODE_ENV=production
PORT=3000
APP_URL=https://your-domain.com

# API Keys (if applicable)
API_KEY=your_api_key_here
API_SECRET=your_api_secret_here

# Database (if applicable)
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# Authentication (if applicable)
JWT_SECRET=your_jwt_secret
SESSION_SECRET=your_session_secret

# External Services
LOG_LEVEL=info
```

### Secrets Management

#### GitHub Secrets
Set secrets in GitHub repository settings for CI/CD:
```
VERCEL_TOKEN
VERCEL_ORG_ID
VERCEL_PROJECT_ID
```

#### Vercel Environment Variables
1. Go to Vercel project settings
2. Navigate to "Environment Variables"
3. Add production, preview, and development variables

## CI/CD Pipeline

### GitHub Actions Workflows

The project includes three main workflows:

#### 1. Test (`test.yml`)
- Runs on push to `main` and `develop`
- Runs on all pull requests
- Tests against Node.js 18.x and 20.x
- Uploads coverage reports

#### 2. Lint (`lint.yml`)
- Runs ESLint
- Checks code formatting
- Runs TypeScript type checking

#### 3. Deploy (`deploy.yml`)
- Runs on push to `main`
- Builds the application
- Runs tests
- Deploys to production (Vercel)
- Sends deployment notifications

### Triggering Deployments

```bash
# Manual deployment trigger
gh workflow run deploy.yml

# View workflow status
gh run list --workflow=deploy.yml

# View logs
gh run view <run-id> --log
```

## Monitoring & Observability

### Health Checks

```bash
# Basic health check
curl https://your-domain.com/health

# Detailed status
curl https://your-domain.com/api/status
```

### Logging

Configure structured logging:
```javascript
// logger.js
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

### Performance Monitoring

Integrate monitoring services:
- **Vercel Analytics**: Automatically enabled on Vercel
- **Sentry**: For error tracking
- **DataDog/New Relic**: For APM

### Metrics to Monitor
- Response times
- Error rates
- CPU/Memory usage
- Request throughput
- Database query performance

## Rollback Procedures

### Vercel Rollback
```bash
# List deployments
vercel ls

# Rollback to specific deployment
vercel rollback <deployment-url>
```

### GitHub Actions Rollback
```bash
# Revert commit
git revert <commit-hash>
git push origin main

# Or redeploy previous commit
git checkout <previous-commit>
vercel --prod
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Clear cache and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

#### Environment Variable Issues
```bash
# Verify environment variables
vercel env ls

# Pull environment variables locally
vercel env pull .env.local
```

#### Port Conflicts
```bash
# Find process using port
lsof -i :3000
kill -9 <PID>
```

## Security Best Practices

1. **Never commit secrets** to the repository
2. **Use environment variables** for sensitive data
3. **Enable Dependabot** for dependency updates
4. **Implement rate limiting** on API endpoints
5. **Use HTTPS** in production
6. **Regular security audits**: `npm audit`
7. **Keep dependencies updated**: `npm update`

## Support & Resources

- **Documentation**: [Project Wiki](link-to-wiki)
- **Issue Tracker**: [GitHub Issues](link-to-issues)
- **CI/CD Dashboard**: [GitHub Actions](link-to-actions)
- **Production Dashboard**: [Vercel Dashboard](link-to-vercel)

---

**Last Updated**: December 2025  
**Maintained By**: Development Team
