#!/bin/bash

# Function to install Python 3.9 on Ubuntu/Debian-based systems
install_ubuntu() {
    echo "Detected Ubuntu/Debian. Installing Python 3.9..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install -y python3.9
    sudo apt install -y python3.9-distutils
    wget https://bootstrap.pypa.io/get-pip.py
    python3.9 get-pip.py
    echo "Python 3.9 installation completed on Ubuntu/Debian."
}

# Function to install Python 3.9 on CentOS/RedHat-based systems
install_centos() {
    echo "Detected CentOS/RedHat. Installing Python 3.9..."
    sudo yum install -y gcc openssl-devel bzip2-devel libffi-devel
    cd /usr/src
    sudo wget https://www.python.org/ftp/python/3.9.7/Python-3.9.7.tgz
    sudo tar xzf Python-3.9.7.tgz
    cd Python-3.9.7
    sudo ./configure --enable-optimizations
    sudo make altinstall
    sudo yum install -y python3-pip
    echo "Python 3.9 installation completed on CentOS/RedHat."
}

# Function to install Python 3.9 on macOS using Homebrew
install_macos() {
    echo "Detected macOS. Installing Python 3.9..."
    brew install python@3.9
    echo "Python 3.9 installation completed on macOS."
}

# Function to install Python 3.9 for other Linux distributions (generic)
install_linux() {
    echo "Detected Linux. Installing Python 3.9..."
    sudo apt update
    sudo apt install -y python3.9 python3.9-distutils
    wget https://bootstrap.pypa.io/get-pip.py
    python3.9 get-pip.py
    echo "Python 3.9 installation completed on Linux."
}

# Detect the OS type
OS_TYPE=$(uname -s)

# Handle different operating systems
case $OS_TYPE in
    Linux)
        # Check if the system is Ubuntu/Debian-based
        if [[ -f /etc/lsb-release ]]; then
            install_ubuntu
        # Check if the system is CentOS/RedHat-based
        elif [[ -f /etc/redhat-release ]]; then
            install_centos
        else
            install_linux
        fi
        ;;
    Darwin)
        install_macos
        ;;
    *)
        echo "Unsupported OS: $OS_TYPE. Exiting."
        exit 1
        ;;
esac
