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



```
3. Deploy on Azure VM:
	● Azure VM Setup:
		● Create and configure an Ubuntu-based Azure VM.
		● Install Docker and Docker Compose on the Azure VM.
	● Deployment:
		● Deploy the Dockerized Django application to the Azure VM
		using Docker Compose.
		● Set up Nginx as a reverse proxy for the Django application,
		handling both HTTP and HTTPS traffic.
		● Ensure that the application is accessible via a domain name.
```

### To set up both HTTP and HTTPS for your Dockerized Nginx serving a Django application, you'll need to generate self-signed SSL certificates if you don't have certificates from a Certificate Authority. Here’s a step-by-step guide to achieve this setup:

### Prerequisites
Docker and Docker Compose installed on your machine.
Nginx configured as a reverse proxy.
Django application ready to be served.

Step 1: Generate Self-Signed SSL Certificates
First, you need to create SSL certificates to use for HTTPS:

```mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./certs/nginx-selfsigned.key -out ./certs/nginx-selfsigned.crt```

You will be prompted to enter details for the certificate. For local testing, you can fill these out arbitrarily.

Step 2: Configure Nginx
You've already outlined the correct Nginx configuration. Ensure the paths to your certificates in the Nginx configuration match where you've stored them:

nginx.conf should point to the correct paths for ssl_certificate and ssl_certificate_key.
Step 3: Set Up Docker Compose
Configure your docker-compose.yml to mount the Nginx configuration and the certificates:

```
version: '3.8'

services:
  web:
    build: .
    volumes:
      - .:/app
    command: gunicorn myproject.wsgi:application --bind 0.0.0.0:8000
    depends_on:
      - db

  db:
    image: postgres
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - web
```
Step 4: Start Your Application
Navigate to the directory containing your docker-compose.yml and run:

```docker-compose up --build -d```

This command builds the images if necessary, starts the containers in detached mode, and ensures they are up and running.

Step 5: Verify the Setup
Check HTTP:

```curl -v http://localhost```

Check HTTPS:

```curl -vk https://localhost```

The -k or --insecure flag with curl is used to bypass SSL verification, which is necessary with self-signed certificates as they are not trusted by default.


