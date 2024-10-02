#!/bin/bash

########## REDEPLOY SCRIPT ##########
#
# This script is used to automatically build directus extensions if they have changed
# and redeploy the Docker services if the docker-compose.yml file has changed.
#
######## END REDEPLOY SCRIPT ########

# Pull the latest changes from git
git pull

# ---- EXTENSIONS LOGIC ----

# File to store last known commit hashes for extensions
LAST_COMMIT_FILE_EXTENSIONS=".last_commit_extensions"

# Extensions directory
EXTENSIONS_DIR="./extensions"

# Get a list of all extension directories (excluding the .registry directory)
EXTENSIONS=$(find "$EXTENSIONS_DIR" -maxdepth 1 -mindepth 1 -type d ! -name ".registry")

# Load the previous commit hashes from the last commit file
declare -A LAST_COMMITS
if [ -f "$LAST_COMMIT_FILE_EXTENSIONS" ]; then
  while IFS= read -r line; do
    IFS='=' read -ra KV <<< "$line"
    LAST_COMMITS["${KV[0]}"]="${KV[1]}"
  done < "$LAST_COMMIT_FILE_EXTENSIONS"
fi

# Temporary file to store the new commit hashes for extensions
NEW_COMMITS_TMP=$(mktemp)

for EXTENSION_PATH in $EXTENSIONS; do
  EXTENSION_NAME=$(basename "$EXTENSION_PATH")

  # Get the current commit hash for each extension
  CURRENT_COMMIT_EXTENSION=$(git log -n 1 --pretty=format:%H -- "$EXTENSION_PATH")

  # Check if the extension has changed since the last pull
  if [ "${LAST_COMMITS["$EXTENSION_NAME"]}" != "$CURRENT_COMMIT_EXTENSION" ]; then
    echo "Extension $EXTENSION_NAME has changed. Running pnpm build..."
    docker run --rm -v "$EXTENSION_PATH:/app" -w /app node:20 bash -c "corepack enable pnpm && pnpm install && pnpm build"

    # Save the current commit hash to the temporary file
    echo "$EXTENSION_NAME=$CURRENT_COMMIT_EXTENSION" >> "$NEW_COMMITS_TMP"
  else
    echo "No changes in $EXTENSION_NAME."
    # Save the same commit hash to the temporary file
    echo "$EXTENSION_NAME=${LAST_COMMITS["$EXTENSION_NAME"]}" >> "$NEW_COMMITS_TMP"
  fi
done

# Replace the old commit file with the new one
mv "$NEW_COMMITS_TMP" "$LAST_COMMIT_FILE_EXTENSIONS"

# ---- DOCKER COMPOSE LOGIC ----

# File to store last known commit hash for docker-compose.yml
LAST_COMMIT_FILE_DOCKER=".last_commit_docker_compose"

# Get the current commit hash of docker-compose.yml
CURRENT_COMMIT_DOCKER=$(git log -n 1 --pretty=format:%H -- docker-compose.yml)

# Check if the last commit file for docker-compose.yml exists, and read the previous commit
if [ -f "$LAST_COMMIT_FILE_DOCKER" ]; then
  LAST_COMMIT_DOCKER=$(cat "$LAST_COMMIT_FILE_DOCKER")
else
  LAST_COMMIT_DOCKER=""
fi

# Compare the last and current commit hashes for docker-compose.yml
if [ "$LAST_COMMIT_DOCKER" != "$CURRENT_COMMIT_DOCKER" ]; then
  echo "docker-compose.yml has changed. Restarting Docker services."
  docker-compose down && docker-compose up -d
  # Update the last commit file with the new commit hash
  echo "$CURRENT_COMMIT_DOCKER" > "$LAST_COMMIT_FILE_DOCKER"
else
  echo "docker-compose.yml has not changed. No need to restart Docker services."
fi

echo "Process completed!"
