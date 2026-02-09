# Jenkins with Docker & Docker Compose Setup Guide
## NOTE: This is for local testing only

This guide walks you through setting up Jenkins in a Docker container with full Docker and Docker Compose support on macOS.

## Prerequisites

- Docker Desktop installed and running on your Mac
- Terminal access
- Basic knowledge of Docker and Jenkins

## Step 1: Create Docker Compose Configuration

Create a `docker-compose.yml` file with the following content:

```yaml
version: '3.8'

services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    user: root  # Run as root to access Docker socket(not recommended for production)
    ports:
      - "8080:8080"   # Jenkins Web UI
      - "50000:50000" # Jenkins agent port
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock  # Mount Docker socket
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock

volumes:
  jenkins_home:
```

## Step 2: Start Jenkins Container

Navigate to the directory containing your `docker-compose.yml` and run:

```bash
docker-compose up -d
```

Wait for Jenkins to start (may take 1-2 minutes).

## Step 3: Install Docker CLI and Docker Compose Plugin

Since we're running on macOS, we need to install Docker tools inside the Jenkins container:

```bash
docker exec -u root jenkins bash -c "
  apt-get update && \
  apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
  echo \
    \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    \$(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
  apt-get update && \
  apt-get install -y docker-ce-cli docker-compose-plugin
"
```

This installation takes a few minutes. Wait for it to complete.

## Step 4: Verify Docker Installation

Check that Docker and Docker Compose are working inside Jenkins:

```bash
# Check Docker version
docker exec jenkins docker --version

# Check Docker Compose version
docker exec jenkins docker compose version
```

Expected output:
```
Docker version 29.x.x, build xxxxxxx
Docker Compose version v5.x.x
```

## Step 5: Get Jenkins Initial Admin Password

Retrieve the initial admin password to unlock Jenkins:

```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Copy the password that appears.

## Step 6: Access Jenkins Web UI

1. Open your browser and navigate to: `http://localhost:8080`
2. Paste the initial admin password
3. Click **Continue**
4. Choose **Install suggested plugins**
5. Create your first admin user
6. Click **Save and Finish**

## Step 7: Install Required Jenkins Plugins

1. Go to **Manage Jenkins** → **Plugins** → **Available plugins**
2. Search for and install:
   - **Docker Pipeline**
   - **Docker Plugin**
   - **Git Plugin** (usually pre-installed)

3. Restart Jenkins if prompted

## Step 8: Configure Jenkins Credentials (Optional)

If you need to use environment files (`.env`):

1. Go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **Add Credentials**
3. Select **Secret file** from Kind dropdown
4. Upload your `.env` file
5. Set ID to `django-env-file` (or your preferred ID)
6. Click **Create**

## Example Jenkinsfile

Here's a sample Jenkinsfile for a Django project with Docker Compose:

```groovy
pipeline {
    agent any
    
    environment {
        COMPOSE_PROJECT_NAME = "bantuware"
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                // Copy .env file from Jenkins credentials
                withCredentials([file(credentialsId: 'django-env-file', variable: 'ENV_FILE')]) {
                    sh 'cp $ENV_FILE .env'
                }
            }
        }
        
        stage('Build Containers') {
            steps {
                sh 'docker compose build'
            }
        }
        
        stage('Stop Old Containers') {
            steps {
                sh 'docker compose down || true'
            }
        }
        
        stage('Start Containers') {
            steps {
                sh 'docker compose up -d'
            }
        }
    }
    
    post {
        success {
            echo 'Deployment completed successfully.'
        }
        failure {
            echo 'Deployment failed.'
        }
    }
}
```

## Troubleshooting

### Permission Denied Error

If you get "Permission denied" when running Docker commands:

```bash
docker exec -u root jenkins chmod 666 /var/run/docker.sock
```

### Docker Not Found

If Docker commands aren't recognized, re-run the Docker installation command from Step 3.

### Jenkins Won't Start

Check the logs:
```bash
docker logs jenkins
```

### Can't See .env Files on Mac

Press `Command + Shift + .` in Finder to show hidden files.

## Useful Commands

### View Jenkins Logs
```bash
docker logs -f jenkins
```

### Restart Jenkins
```bash
docker-compose restart
```

### Stop Jenkins
```bash
docker-compose down
```

### Start Fresh (Remove All Data)
```bash
docker-compose down
docker volume rm jenkins_home
docker-compose up -d
```

### Access Jenkins Container Shell
```bash
docker exec -it jenkins bash
```

### Check Running Containers from Jenkins
```bash
docker exec jenkins docker ps
```

## Architecture Overview

```
┌─────────────────────────────────────┐
│         macOS Host                  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   Jenkins Container          │  │
│  │   - User: root               │  │
│  │   - Port: 8080, 50000        │  │
│  │   - Docker CLI installed     │  │
│  │   - Docker Compose installed │  │
│  │                              │  │
│  │   /var/run/docker.sock ──────┼──┼──> Docker Desktop
│  │   (mounted from host)        │  │
│  └──────────────────────────────┘  │
│                                     │
│  ┌──────────────────────────────┐  │
│  │   Your Application Container │  │
│  │   (managed by Jenkins)       │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Security Notes

- Running Jenkins as `root` is acceptable for local development
- For production, consider using proper user permissions and groups
- Never commit `.env` files with secrets to Git
- Use Jenkins credentials management for sensitive data

## Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)

---

**Created by:** Isaya Bendera  
**Date:** February 2026  
**Version:** 1.0