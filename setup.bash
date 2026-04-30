#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Get the absolute path of the current directory (the repo root)
REPO_DIR=$(pwd)

echo "================================================================="
echo " Starting setup for Airan (Open5GS, UHD, srsRAN)"
echo "================================================================="

# 1. Update System and Install Core Dependencies
echo "[1/6] Updating system and installing dependencies..."
sudo apt update
sudo apt install -y build-essential cmake libfftw3-dev libmbedtls-dev \
    libconfig++-dev libsctp-dev libyaml-cpp-dev \
    libgtest-dev git net-tools curl wget software-properties-common gnupg \
    libzmq3-dev

# Install MongoDB 8.0 (Required for Open5GS on Ubuntu 24.04)
echo "Installing MongoDB..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor --yes
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
   sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
sudo apt update
sudo apt install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod

# 2. Install and Configure Open5GS
echo "[2/6] Installing Open5GS..."
sudo add-apt-repository ppa:open5gs/latest -y
sudo apt update
sudo apt install -y open5gs

echo "Applying Open5GS configurations from repository..."
if [ -f "$REPO_DIR/amf.yaml" ] && [ -f "$REPO_DIR/nrf.yaml" ] && [ -f "$REPO_DIR/upf.yaml" ]; then
    sudo cp "$REPO_DIR/amf.yaml" /etc/open5gs/amf.yaml
    sudo cp "$REPO_DIR/nrf.yaml" /etc/open5gs/nrf.yaml
    sudo cp "$REPO_DIR/upf.yaml" /etc/open5gs/upf.yaml
    
    echo "Restarting Open5GS services to apply new configurations..."
    sudo systemctl restart open5gs-amfd
    sudo systemctl restart open5gs-nrfd
    sudo systemctl restart open5gs-upfd
else
    echo "Warning: amf.yaml, nrf.yaml, or upf.yaml not found in $REPO_DIR!"
    echo "Please ensure they are in the correct location."
fi

# 3. Install UHD Driver and Download Base Images
echo "[3/6] Installing UHD Drivers..."
sudo apt install -y libuhd-dev uhd-host

echo "Downloading base UHD images..."
sudo uhd_images_downloader

# 4. Handle UHD Images
echo "[4/6] Configuring Custom UHD Images..."
UHD_IMAGES_DIR="$REPO_DIR/UHD_images"
SELECTED_UHD_IMAGE=""

# Step 4a: Select the source image from the repository
if [ -d "$UHD_IMAGES_DIR" ]; then
    echo "Please select the UHD image you want to use from the UHD_images folder:"
    PS3="Enter the number of your choice: "
    
    # List all files/folders inside UHD_images
    options=("$UHD_IMAGES_DIR"/*)
    select opt in "${options[@]}"; do
        if [ -n "$opt" ]; then
            SELECTED_UHD_IMAGE="$opt"
            echo "You selected: $(basename "$SELECTED_UHD_IMAGE")"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
else
    echo "Warning: Directory $UHD_IMAGES_DIR does not exist in the repository."
    echo "Skipping custom local UHD image setup."
fi

# Step 4b: If an image was selected, ask where to put it
if [ -n "$SELECTED_UHD_IMAGE" ]; then
    BASE_UHD_DIR="/usr/share/uhd"
    echo "Checking available folders in $BASE_UHD_DIR..."

    if [ -d "$BASE_UHD_DIR" ]; then
        shopt -s nullglob
        available_dirs=("$BASE_UHD_DIR"/*/)
        shopt -u nullglob

        if [ ${#available_dirs[@]} -gt 0 ]; then
            echo "Please select the target directory for the custom UHD image:"
            options=("${available_dirs[@]}" "Type a custom path instead")
            
            PS3="Enter the number of your choice: "
            select choice in "${options[@]}"; do
                if [[ "$choice" == "Type a custom path instead" ]]; then
                    read -r -p "Enter custom path [/usr/share/uhd/images]: " TARGET_UHD_DIR
                    TARGET_UHD_DIR=${TARGET_UHD_DIR:-/usr/share/uhd/images}
                    break
                elif [[ -n "$choice" ]]; then
                    TARGET_UHD_DIR="$choice"
                    break
                else
                    echo "Invalid selection. Please try again."
                fi
            done
        else
            echo "No subdirectories found in $BASE_UHD_DIR."
            read -r -p "Enter target directory [/usr/share/uhd/images]: " TARGET_UHD_DIR
            TARGET_UHD_DIR=${TARGET_UHD_DIR:-/usr/share/uhd/images}
        fi
    else
        echo "Directory $BASE_UHD_DIR does not exist."
        read -r -p "Enter target directory [/usr/share/uhd/images]: " TARGET_UHD_DIR
        TARGET_UHD_DIR=${TARGET_UHD_DIR:-/usr/share/uhd/images}
    fi

    # Clean up any trailing slashes and copy
    TARGET_UHD_DIR=${TARGET_UHD_DIR%/}
    echo "Target directory set to: $TARGET_UHD_DIR"
    
    sudo mkdir -p "$TARGET_UHD_DIR"
    echo "Copying custom image to $TARGET_UHD_DIR..."
    sudo cp -r "$SELECTED_UHD_IMAGE" "$TARGET_UHD_DIR/"
    echo "Custom UHD Image copied successfully."
fi

# 5. Clone and Build srsRAN_4G
echo "[5/6] Building srsRAN_4G..."
cd ~
if [ ! -d "srsRAN_4G" ]; then
    git clone https://github.com/srsran/srsRAN_4G.git
fi
cd srsRAN_4G
mkdir -p build && cd build
cmake ../
make -j$(nproc)
sudo make install
sudo srsran_install_configs.sh user
sudo ldconfig

# 6. Clone and Build srsRAN_Project (5G)
echo "[6/6] Building srsRAN_Project (5G)..."
cd ~
if [ ! -d "srsRAN_Project" ]; then
    git clone https://github.com/srsran/srsRAN_Project.git
fi
cd srsRAN_Project
mkdir -p build && cd build
cmake ../
make -j$(nproc)
sudo make install
sudo ldconfig

echo "================================================================="
echo " Setup Complete! "
echo "================================================================="