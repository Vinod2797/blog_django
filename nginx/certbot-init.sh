#!/bin/bash

# Run Certbot to obtain the initial SSL certificate
certbot certonly --webroot --webroot-path=/var/www/certbot \
  -d absolutetechsol.com -d www.absolutetechsol.com \
  --email vinod@gmail.com --agree-tos --non-interactive

# Ensure SSL lines are uncommented in the Nginx config
sed -i 's|# ssl_certificate|ssl_certificate|' /etc/nginx/conf.d/default.conf
sed -i 's|# ssl_certificate_key|ssl_certificate_key|' /etc/nginx/conf.d/default.conf

# Reload Nginx to apply the SSL configuration
nginx -s reload

