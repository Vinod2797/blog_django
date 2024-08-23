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
## 1.1 Install Dependencies:

Set up a local development environment on Ubuntu:

```
sudo apt update
sudo apt upgrade
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
mkdir django_project
cd django_project
python3 -m venv venv
source venv/bin/activate
pip install django psycopg2-binary
django-admin startproject myproject .
cd myproject
django-admin startapp blog
```

Configure the project to use PostgreSQL as the database: Edit blog_django/webapp/settings.py:

```
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'mydatabase',
        'USER': 'mydatabaseuser',
        'PASSWORD': 'mypassword',
        'HOST': 'db',
        'PORT': '5432',
    }
}
```

# 2. Containerize the Application
## 2.1 Dockerize Django Application:

Write a Dockerfile: Create a Dockerfile in the root of your project:
```
FROM python:3.9-slim

ENV PYTHONUNBUFFERED 1

WORKDIR /app

COPY requirements.txt /app/
RUN pip install -r requirements.txt

COPY . /app/

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]
```

Create a docker-compose.yml file:
```
version: '3'

services:
  db:
    image: postgres:13
    environment:
      POSTGRES_DB: mydatabase
      POSTGRES_USER: mydatabaseuser
      POSTGRES_PASSWORD: mypassword
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    volumes:
      - .:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgres://mydatabaseuser:mypassword@db:5432/mydatabase

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
    depends_on:
      - web

volumes:
  postgres_data:
```

Ensure that the application can be started with a single command:

```docker-compose up```

## 2.2 Database Configuration:

Ensure that the Django application connects to the PostgreSQL container using environment variables: Edit myproject/settings.py to use environment variables:
```
import os
import dj_database_url

DATABASES = {
    'default': dj_database_url.config(default=os.environ.get('DATABASE_URL'))
}
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


