#!/bin/bash

#update from git
git pull

# Function to install jq if not already installed
install_jq() {
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing..."
        sudo apt-get update
        sudo apt-get install -y jq
        echo "jq installed successfully."
    fi
}

# Function to create and activate a virtual environment
create_venv() {
    if [ ! -d "venv" ]; then
        echo "Creating virtual environment..."
        python3 -m venv venv
        echo "Virtual environment created."
    fi
    source venv/bin/activate
}

# Check if Python 3 is available, if not, attempt to install it
if ! command -v python3 &> /dev/null; then
    echo "Python 3 is not installed. Attempting to install..."
    sudo apt-get update
    sudo apt-get install -y python3
    if [ $? -eq 0 ]; then
        echo "Python 3 installed successfully."
    else
        echo "Failed to install Python 3. Please install Python 3 manually and run the script again."
        exit 1
    fi
fi

# Set execute permission for the script
chmod +x "$0"

# Install jq
install_jq

# Create and activate the virtual environment
cd ~/ListenX/ListenX || exit
create_venv

# Install Whisper
git clone https://github.com/ggerganov/whisper.cpp
cd ~/whisper.cpp
make -j stream
./models/download-ggml-model.sh tiny.en

# Define variables
OWNER="aiembed"
REPO="ListenX"
SERVICE_NAME="listenx.service"

# Get the latest release information using GitHub API
LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" | jq -r '.tag_name')

# Construct the download URL for the Python script
SCRIPT_URL="https://raw.githubusercontent.com/$OWNER/$REPO/$LATEST_RELEASE/$SCRIPT_NAME"

# Check if the Python script exists
if [ -f "$SCRIPT_NAME" ]; then
    echo "Python script '$SCRIPT_NAME' found."
else
    echo "Downloading Python script '$SCRIPT_NAME' from $SCRIPT_URL..."
    wget "$SCRIPT_URL"
    if [ $? -eq 0 ]; then
        echo "Python script '$SCRIPT_NAME' downloaded successfully."
    else
        echo "Failed to download Python script. Exiting."
        exit 1
    fi
fi

# Set execute permission for the script
chmod +x "$SCRIPT_NAME"

# Create the systemd service file
cat <<EOF | sudo tee "/etc/systemd/system/$SERVICE_NAME" > /dev/null
[Unit]
Description=Run ListenX script on startup

[Service]
ExecStart=/home/pi/ListenX/venv/bin/python3 /home/pi/ListenX/$SCRIPT_NAME
WorkingDirectory=/home/pi/ListenX
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable the service
sudo systemctl enable "$SERVICE_NAME"

# Start the service
sudo systemctl start "$SERVICE_NAME"

echo "Setup completed."
