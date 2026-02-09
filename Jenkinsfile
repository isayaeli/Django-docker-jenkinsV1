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
