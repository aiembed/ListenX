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
cd ~/ListenX || exit
create_venv

# Set execute permission for the script
chmod +x "$SCRIPT_NAME"

# Install Whisper if not already installed
WHISPER_DIR="$HOME/ListenX/whisper.cpp"
if [ ! -d "$WHISPER_DIR" ]; then
    echo "Cloning Whisper repository..."
    git clone https://github.com/ggerganov/whisper.cpp "$WHISPER_DIR"
    echo "Whisper repository cloned successfully."
    echo "Building Whisper..."
    cd "$WHISPER_DIR"
    make -j stream
    echo "Whisper built successfully."
else
    echo "Whisper is already installed. Skipping installation."
fi

# Check if Whisper model files exist
MODEL_DIR="$WHISPER_DIR/models"
MODEL_FILE="tiny.en"
MODEL_PATH="$MODEL_DIR/$MODEL_FILE"

if [ -f "$MODEL_PATH" ]; then
    echo "Whisper model '$MODEL_FILE' already exists. Skipping download."
else
    echo "Downloading Whisper model '$MODEL_FILE'..."
    cd "$WHISPER_DIR"  # Move to Whisper directory
    bash ./models/download-ggml-model.sh "$MODEL_FILE"
    if [ $? -eq 0 ]; then
        echo "Whisper model '$MODEL_FILE' downloaded successfully."
    else
        echo "Failed to download Whisper model. Exiting."
        exit 1
    fi
fi


# Define variables
OWNER="aiembed"
REPO="ListenX"
SERVICE_NAME="listenx.service"
SCRIPT_NAME="fan.py"

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


