# Blog - Django

  ## Description

  A personal Blog application built using Django (Python) and PostgreSQL. Admin users create Blog posts and site visitors can view posts, comment on posts, & save posts to read later.  PostgreSQL used for database storage.


  
  ## Installation
  
  Deployed URL:  hhttp://20.193.158.152/
  
  ## Usage
  
  Visit deployed URL, view posts, comment on individual posts, or save individual posts to read later.


  
  ## Contributing
  N/A
  
  ## Tests
  N/A


#================================================================
# 1. Setup the Development Environment
## 1.1 Install Dependencies: (branch: release3)

Set up a local development environment on Ubuntu:

```
sudo apt update
sudo apt upgrade -y
```

Install Python, Docker, and Docker Compose:
```
sudo apt install python3 python3-pip
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo apt install docker-compose
```

## 1.2 Create a Django Project:

Initialize a Django project with a basic app:
```
mkdir -p blog_django
cd  blog_django
python3 -m venv venv
source venv/bin/activate
pip install django psycopg2-binary
django-admin startproject blog_django .
django-admin startapp blog
```

Configure the project to use PostgreSQL as the database: Edit blog_django/webapp/settings.py:

```
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'blogdb',
        'USER': 'dbadminuser',
        'PASSWORD': 'myP@ssw0rd',
        'HOST': 'db',
        'PORT': '5432',
    }
}
```

# 2. Containerize the Application
## 2.1 Dockerize Django Application:

Write a Dockerfile: Create a Dockerfile in the root of your project:
```
# Use the official Python image from the Docker Hub
FROM python:3.12-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

# Copy the requirements file
COPY requirements.txt /app/

# Install the dependencies
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy the rest of the application code
COPY . /app/

# Make the wait-for-it.sh script executable
RUN chmod +x /app/wait-for-it.sh

# Expose the port the app runs on
EXPOSE 8000

# Run the application
CMD ["sh", "-c", "./wait-for-it.sh db:5432 -- gunicorn --bind 0.0.0.0:8000 blog_django.wsgi:application"]
```

Create a docker-compose.yml file:
```
version: '3.8'

services:
  db:
    image: postgres:16
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sh:/docker-entrypoint-initdb.d/init-db.sh
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: myP@ssw0rd
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    build: .
    command: >
      sh -c "
      python manage.py migrate &&
      gunicorn --bind 0.0.0.0:8000 blog_django.wsgi:application
      "
    volumes:
      - .:/app
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_NAME: blogdb
      DATABASE_USER: dbadminuser
      DATABASE_PASSWORD: myP@ssw0rd
      DATABASE_HOST: db
      DATABASE_PORT: 5432
      ALLOWED_HOSTS: '*'
      DJANGO_SUPERUSER_USERNAME: admin
      DJANGO_SUPERUSER_EMAIL: admin@gmail.com
      DJANGO_SUPERUSER_PASSWORD: Admin@123

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./staticfiles:/app/staticfiles
      - ./uploads:/app/uploads
    depends_on:
      - web

volumes:
  postgres_data:
```

Ensure that the application can be started with a single command:

```docker-compose up```

## 2.2 Database Configuration:

Ensure that the Django application connects to the PostgreSQL container using environment variables: Edit blog_django/settings.py to use environment variables:
```
import os
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'blogdb',
        'USER': 'dbadminuser',
        'PASSWORD': 'myP@ssw0rd',
        'HOST': 'db',
        'PORT': '5432',
    }
}
```

To make migrations and start the app:
```
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:8000 
```


# 3. Deploy on Azure VM:
	● Azure VM Setup:
		● Create and configure an Ubuntu-based Azure VM.
		● Install Docker and Docker Compose on the Azure VM.
	● Deployment:
		● Deploy the Dockerized Django application to the Azure VM
		using Docker Compose.
		● Set up Nginx as a reverse proxy for the Django application,
		handling both HTTP and HTTPS traffic.
		● Ensure that the application is accessible via a domain name.



### To set up both HTTP and HTTPS for your Dockerized Nginx serving a Django application, you'll need to generate self-signed SSL certificates if you don't have certificates from a Certificate Authority. Here’s a step-by-step guide to achieve this setup:

### Prerequisites
Docker and Docker Compose installed on your machine.
Nginx configured as a reverse proxy.
Django application ready to be served.

## Azure VM Setup
Create and Configure an Ubuntu-based Azure VM:
Follow the Azure documentation to create an Ubuntu VM: https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu

Install Docker and Docker Compose on the Azure VM:
SSH into your Azure VM and run the following commands:
```
sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Deployment
## 3.1: Generate Self-Signed SSL Certificates
First, you need to create SSL certificates to use for HTTPS:
```
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./certs/nginx-selfsigned.key -out ./certs/nginx-selfsigned.crt
```

## 3.2: Configure Nginx
nginx.conf should point to the correct paths for ssl_certificate and ssl_certificate_key.
```
events {}

http {
    # Server for HTTP
    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://web:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /static/ {
            alias /app/staticfiles/;
        }

        location /media/ {
            alias /app/uploads/;
        }
    }

    # Server for HTTPS
    server {
        listen 443 ssl;
        server_name localhost;

        ssl_certificate /etc/nginx/certs/nginx-selfsigned.crt;
        ssl_certificate_key /etc/nginx/certs/nginx-selfsigned.key;

        ssl_session_cache shared:SSL:1m;
        ssl_session_timeout  10m;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            proxy_pass http://web:8000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /static/ {
            alias /app/staticfiles/;
        }

        location /media/ {
            alias /app/uploads/;
        }
    }
}
```
## 3.3: Set Up Docker Compose
Configure your docker-compose.yml to mount the Nginx configuration and the certificates:

```
version: '3.8'

services:
  db:
    image: postgres:16
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-db.sh:/docker-entrypoint-initdb.d/init-db.sh
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: myP@ssw0rd
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  web:
    build: .
    command: >
      sh -c "
      python manage.py migrate &&
      gunicorn --bind 0.0.0.0:8000 blog_django.wsgi:application
      "
    volumes:
      - ./webapp:/app
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_NAME: blogdb
      DATABASE_USER: dbadminuser
      DATABASE_PASSWORD: myP@ssw0rd
      DATABASE_HOST: db
      DATABASE_PORT: 5432
      ALLOWED_HOSTS: '*'
      DJANGO_SUPERUSER_USERNAME: admin
      DJANGO_SUPERUSER_EMAIL: admin@gmail.com
      DJANGO_SUPERUSER_PASSWORD: Admin@123

  nginx:
    build: ./nginx
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web

volumes:
  postgres_data:
```
## 3.4: Start Your Application
Navigate to the directory containing your docker-compose.yml and run:

```docker-compose up --build -d```

This command builds the images if necessary, starts the containers in detached mode, and ensures they are up and running.

## 3.5: Verify the Setup
Check HTTP:

```curl -v http://localhost```

Check HTTPS:

```curl -vk https://localhost```

The -k or --insecure flag with curl is used to bypass SSL verification, which is necessary with self-signed certificates as they are not trusted by default.



# 4. Configure and Secure the Application: 
	● SSL/TLS Setup:
		● Obtain and configure SSL certificates for the domain using Let’s
		Encrypt.
		● Ensure that the application enforces HTTPS.

we tried less encrypt but we don't have any DNS domain names. So, here logs for
### LOGS ####

```
root@myweb:~/blog_django# docker-compose ps
       Name                      Command                  State        Ports
------------------------------------------------------------------------------
blog_django_db_1      docker-entrypoint.sh postgres    Up (healthy)   5432/tcp
blog_django_nginx_1   /bin/bash -c /certbot-init ...   Exit 1
blog_django_web_1     sh -c  python manage.py mi ...   Up             8000/tcp
root@myweb:~/blog_django#
root@myweb:~/blog_django#
root@myweb:~/blog_django# docker-compose logs nginx
Attaching to blog_django_nginx_1
nginx_1  | Saving debug log to /var/log/letsencrypt/letsencrypt.log
nginx_1  | Requesting a certificate for absolutetechsol.com and www.absolutetechsol.com
nginx_1  |
nginx_1  | Certbot failed to authenticate some domains (authenticator: webroot). The Certificate Authority reported these problems:
nginx_1  |   Domain: absolutetechsol.com
nginx_1  |   Type:   connection
nginx_1  |   Detail: 20.193.158.152: Fetching http://absolutetechsol.com/.well-known/acme-challenge/gQHMS3N_KklMW7mxiSE3aeQyvy0IovAysgcCbo_vsac: Connection refused
nginx_1  |
nginx_1  |   Domain: www.absolutetechsol.com
nginx_1  |   Type:   connection
nginx_1  |   Detail: 20.193.158.152: Fetching http://www.absolutetechsol.com/.well-known/acme-challenge/odAKID0HRupa2mVLkPaVWf923Zp4Rahrzb39k6KQLfk: Connection refused
nginx_1  |
nginx_1  | Hint: The Certificate Authority failed to download the temporary challenge files created by Certbot. Ensure that the listed domains serve their content from the provided --webroot-path/-w and that files created there can be downloaded from the internet.
nginx_1  |
nginx_1  | Some challenges have failed.
nginx_1  | Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
nginx_1  | sed: cannot rename /etc/nginx/conf.d/sedWkstaU: Device or resource busy
nginx_1  | sed: cannot rename /etc/nginx/conf.d/sed0VWvYT: Device or resource busy
nginx_1  | 2024/08/22 21:53:43 [emerg] 11#11: cannot load certificate "/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
nginx_1  | nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
nginx_1  | 2024/08/22 21:53:43 [emerg] 13#13: cannot load certificate "/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
nginx_1  | nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem": BIO_new_file() failed (SSL: error:80000002:system library::No such file or directory:calling fopen(/etc/letsencrypt/live/absolutetechsol.com/fullchain.pem, r) error:10000080:BIO routines::no such file)
root@myweb:~/blog_django#
root@myweb:~/blog_django#

```


## 	● Security Hardening:
		● Implement security best practices for Nginx and Django (e.g.,
		secure headers, rate limiting).
		● Set up a firewall on the Azure VM to restrict access to
		necessary ports (e.g., 80, 443, 22).

 Security Hardening
Configure secure headers and rate limiting in Nginx.
Set up UFW (Uncomplicated Firewall):
```
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw enable
```


# 5. Automate Deployment:
	● CI/CD Pipeline:
		● Create a simple CI/CD pipeline using a tool like GitHub Actions,
		GitLab CI, or Jenkins.
		● Automate the build, test, and deployment of the Dockerized
		Django application to the Azure VM.
		● Ensure that the pipeline can be triggered by a commit to the
		main branch.

## 5.1: Multibranch pipeline with webhook
```http://15.207.104.237:8080/job/django-app-deploy-webhook/job/main/3/console```
## Webhook: 
```https://github.com/Vinod2797/blog_django/settings/hooks```

## 5.2: Jenkinspipeline
```
pipeline {
    agent any

    #triggers {
    #    // Poll SCM for changes
    #    pollSCM('H/5 * * * *') // Check every 5 minutes; adjust as needed
    #}

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
```

## Graphical view
![image](https://github.com/user-attachments/assets/184f788a-22f9-4ca8-90c2-7a6b7e27966e)

# 6. Monitoring and Logging:
		● Monitoring:
			● Set up monitoring for the application using a tool like Prometheus and Grafana, or Azure Monitor.
   			● Monitor key metrics such as CPU usage, memory usage, and response time.
		 ● Logging:
   			● Configure centralized logging for the Django application and Nginx using tools like ELK Stack (Elasticsearch, Logstash, Kibana) or Azure Log Analytics.
   			● Ensure logs are easily accessible for troubleshooting

 ### In Progress...

# 7. Backup and Restore:
		● Database Backup:
			● Set up a backup strategy for PostgreSQL using a tool like pg_dump or Azure Backup.
			● Create a script to automate daily backups and store the securely.
   		● Restore Process:
			● Document and test the process to restore the database from a backup.

 ### In Progress...



