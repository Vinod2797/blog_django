pipeline {
    agent any

    triggers {
        // Poll SCM for changes
        pollSCM('H/5 * * * *') // Check every 5 minutes; adjust as needed
    }

    environment {
        SSH_CREDENTIALS = credentials('azure-vm-ssh')
        AZURE_VM_IP = '20.193.158.152'
        AZURE_VM_USER = 'ubuntu'
        ALLOWED_HOSTS = '20.193.158.152'
        DJANGO_SUPERUSER_USERNAME = 'admin'
        DJANGO_SUPERUSER_EMAIL = 'admin@gamil.com'
        DJANGO_SUPERUSER_PASSWORD = 'Admin@123'
        GIT_REPO_URL = 'https://github.com/Vinod2797/blog_django.git'
        PROJECT_DIR = '/home/ubuntu/blog_django'
    }

    stages {
	
	    stage('Git Checkout') {
            steps {
                script {
                    sshagent(credentials: ['SSH_CREDENTIALS']) {
                        sh """
                        ssh -T -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} << 'EOF'
                        
                        # Check out the latest code and update the project directory
                        #if [ ! -d "${PROJECT_DIR}" ]; then
                        #    git clone ${GIT_REPO_URL} ${PROJECT_DIR}
                        #else
                        #    cd ${PROJECT_DIR}
                        #    git pull origin main
                        #fi
						
			rm -rf ${PROJECT_DIR}
			git clone ${GIT_REPO_URL} ${PROJECT_DIR}
						
                        """
                    }
                }
            }
        }

        stage('Deploy to Azure VM') {
            steps {
                script {
                    sshagent(credentials: ['SSH_CREDENTIALS']) {
                        sh """
                        ssh -T -o StrictHostKeyChecking=no ${AZURE_VM_USER}@${AZURE_VM_IP} << 'EOF'
                        
                        # Check out the latest code and update the project directory
                        #if [ ! -d "${PROJECT_DIR}" ]; then
                        #    git clone ${GIT_REPO_URL} ${PROJECT_DIR}
                        #else
                        #    cd ${PROJECT_DIR}
                        #    git pull origin main
                        #fi
						
						#rm -rf ${PROJECT_DIR}
						#git clone ${GIT_REPO_URL} ${PROJECT_DIR}
						
						
                        # Change to the project directory
                        cd ${PROJECT_DIR}

                        # Update environment variables in .env or configuration files as needed
                        export ALLOWED_HOSTS=${ALLOWED_HOSTS}
                        export DJANGO_SUPERUSER_USERNAME=${DJANGO_SUPERUSER_USERNAME}
                        export DJANGO_SUPERUSER_EMAIL=${DJANGO_SUPERUSER_EMAIL}
                        export DJANGO_SUPERUSER_PASSWORD=${DJANGO_SUPERUSER_PASSWORD}

                        # Pull the latest Docker image and restart services
                        #docker-compose pull
						sudo docker-compose down
                        sudo docker-compose up --build -d
                        #EOF
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
