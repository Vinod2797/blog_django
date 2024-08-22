pipeline {
    agent any

    environment {
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        SSH_CREDENTIALS = credentials('azure-vm-ssh')
        DOCKER_IMAGE = 'your_dockerhub_username/blog_django'
        AZURE_VM_IP = 'your-azure-vm-ip'
        AZURE_VM_USER = 'your-azure-vm-user'
        ALLOWED_HOSTS = 'your-azure-vm-public-ip'
        DJANGO_SUPERUSER_USERNAME = 'admin'
        DJANGO_SUPERUSER_EMAIL = 'admin@example.com'
        DJANGO_SUPERUSER_PASSWORD = 'adminpassword'
        GIT_REPO_URL = 'https://github.com/yourusername/your-repo.git'
        PROJECT_DIR = '/home/${AZURE_VM_USER}/blog_django'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GIT_REPO_URL}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Generate a unique tag using the build number
                    def imageTag = "${DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                    docker.build(imageTag)
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    // Generate a unique tag using the build number
                    def imageTag = "${DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                    docker.withRegistry('https://index.docker.io/v1/', 'DOCKER_HUB_CREDENTIALS') {
                        docker.image(imageTag).push()
                    }
                }
            }
        }

        stage('Deploy to Azure VM') {
            steps {
                script {
                    // Generate a unique tag using the build number
                    def imageTag = "${DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                    sshagent(credentials: ['SSH_CREDENTIALS']) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} << 'EOF'
                        if [ ! -d "${PROJECT_DIR}" ]; then
                            git clone ${GIT_REPO_URL} ${PROJECT_DIR}
                        else
                            cd ${PROJECT_DIR}
                            git pull origin main
                        fi
                        cd ${PROJECT_DIR}
                        export ALLOWED_HOSTS=${ALLOWED_HOSTS}
                        export DJANGO_SUPERUSER_USERNAME=${DJANGO_SUPERUSER_USERNAME}
                        export DJANGO_SUPERUSER_EMAIL=${DJANGO_SUPERUSER_EMAIL}
                        export DJANGO_SUPERUSER_PASSWORD=${DJANGO_SUPERUSER_PASSWORD}
                        sed -i 's|image: ${DOCKER_IMAGE}:.*|image: ${imageTag}|' docker-compose.yml
                        docker-compose pull
                        docker-compose up -d
                        EOF
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}

