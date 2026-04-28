#!/usr/bin/env bash
# Configuration file for install.sh
# Customize these values according to your preferences

# User information
GIT_USER_NAME="Victor Silva"
GIT_USER_EMAIL="victor.hos@gmail.com"
SSH_KEY_EMAIL="victor.hos@gmail.com"
SSH_KEY_TITLE="desktop-ubuntu"

# Directories
CACHE_DIR="${HOME}/.cache/sabadao-install"
DOWNLOADS_DIR="${CACHE_DIR}/downloads"

# Options
SKIP_GITHUB_LOGIN=false
SKIP_SSH_KEY_GENERATION=false
VERBOSE=false

# Application URLs
CHROME_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
ULAUNCHER_URL="https://github.com/Ulauncher/Ulauncher/releases/download/v6.0.0-beta30/ulauncher_6.0.0.beta30_all.deb"
CURSOR_URL="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/3.0"
AWS_CLI_VERSION="2.0.30"
