#!/bin/bash

# Detect the architecture
ARCH=$(uname -m)

# Determine the appropriate filename based on the architecture
if [[ "$ARCH" == "x86_64" ]]; then
    FILE="s5_deploy-x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
    FILE="s5_deploy-aarch64-linux"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Get the latest release from GitHub API
LATEST_RELEASE_URL="https://api.github.com/repos/s5-dev/s5_deploy/releases/latest"
LATEST_RELEASE=$(curl -s $LATEST_RELEASE_URL)

# Extract the download URL for the appropriate file
DOWNLOAD_URL=$(echo $LATEST_RELEASE | grep -oP '"browser_download_url": "\K(.*?)(?=")' | grep $FILE)

# Check if the download URL was found
if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Failed to find the download URL for $FILE"
    exit 1
fi

echo "$DOWNLOAD_URL"

# Download the file
curl -L -o "/tmp/$FILE" "$DOWNLOAD_URL"

# Make the file executable
chmod +x "/tmp/$FILE"

# Move the file to /usr/local/bin
sudo mv "/tmp/$FILE" /usr/local/bin/s5_deploy

echo "s5_deploy has been installed to /usr/local/bin"

