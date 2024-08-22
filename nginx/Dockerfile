# Use the official Nginx image as a base
FROM nginx:latest

# Install Certbot and dependencies from Debian/Ubuntu repositories
RUN apt-get update && \
    apt-get install -y certbot python3-certbot-nginx && \
    apt-get clean

# Copy the Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the Certbot initialization script
COPY certbot-init.sh /certbot-init.sh
RUN chmod +x /certbot-init.sh

# Prepare webroot directory for Certbot
RUN mkdir -p /var/www/certbot

# Expose ports for HTTP and HTTPS
EXPOSE 80 443

# Start Nginx in the foreground
CMD ["nginx", "-g", "daemon off;"]

