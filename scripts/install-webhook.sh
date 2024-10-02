#!/bin/bash

# Create a webhook on GitHub
curl -X POST -H "Authorization: Bearer ${token}" -H "Accept: application/vnd.github+json" https://api.github.com/repos/${repo}/hooks -d '{"name": "web", "active": true, "events": ["push"], "config": {"url": "http://${domain}:9000/hooks/github", "content_type": "json"}}'

# Install webhook
sudo apt-get install webhook

# Create a hooks.json file
cat > /home/jelastic/hooks.json <<EOF
[
  {
    "id": "github",
    "execute-command": "/home/jelastic/app/${deploy}",
    "command-working-directory": "/home/jelastic/app",
    "response-message": "Redeploying...",
    "trigger-rule": {
      "match": { "value": "refs/heads/${branch}", "type": "payload", "parameter": { "name": "ref" } }
    }
  }
]
EOF

# Ensure deploy script is executable
chmod +x /home/jelastic/app/${deploy}

# Create webhook service
cat > /etc/systemd/system/webhook.service <<EOF
[Unit]
Description=webhook

[Service]
ExecStart=webhook -hooks /home/hooks.json -verbose
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start webhook service
sudo systemctl start webhook

# Enable webhook service
sudo systemctl enable webhook

