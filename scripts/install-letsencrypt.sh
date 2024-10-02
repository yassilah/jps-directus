#!/bin/bash

# Install Let's Encrypt
sudo apt install certbot python3-certbot-apache

# Get the list of domains from nginx in /etc/nginx/sites-enabled/ 
LIST=$(ls -p /etc/nginx/sites-enabled/  | grep -v / | tr '\n' ',')

# Install SSL certificates for each domain
sudo certbot --nginx -d ${LIST} -n --agree-tos -m ${email} --redirect

# Restart nginx
sudo systemctl restart nginx