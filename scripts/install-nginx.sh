#!/bin/bash

# Install nginx
sudo apt-get install nginx

# Create a server block for each domain
LIST="${domains}"

IFS=$'\n' read -r -d '' -a DOMAINS <<< "$(echo -e "$LIST")"

for DOMAIN in "${DOMAINS[@]}"; do
    IFS=':' read -r -a DOMAIN <<< "$DOMAIN"

    cat > /etc/nginx/sites-available/${DOMAIN[0]}.conf <<EOF
server {
    listen 80;
    server_name ${DOMAIN[0]};

    location / {
        proxy_pass http://\$host:${DOMAIN[1]};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

    ln -s /etc/nginx/sites-available/${DOMAIN[0]}.conf /etc/nginx/sites-enabled/${DOMAIN[0]}.conf
done

# Restart nginx
sudo systemctl restart nginx

# Enable nginx
sudo systemctl enable nginx