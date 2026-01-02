#!/usr/bin/env bash
set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.sh"
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
else
  # Default values if config.sh doesn't exist
  GIT_USER_NAME="Victor Silva"
  GIT_USER_EMAIL="victor.hos@gmail.com"
  SSH_KEY_EMAIL="victor.hos@gmail.com"
  SSH_KEY_TITLE="desktop-ubuntu"
  CACHE_DIR="${HOME}/.cache/sabadao-install"
  DOWNLOADS_DIR="${CACHE_DIR}/downloads"
  SKIP_GITHUB_LOGIN=false
  SKIP_SSH_KEY_GENERATION=false
  VERBOSE=false
fi

# Create cache directories
mkdir -p "$DOWNLOADS_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Utility functions
log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
  echo -e "${RED}❌${NC} $1"
}

# Timer functions
start_timer() {
  TIMER_START=$(date +%s)
}

end_timer() {
  local TIMER_END=$(date +%s)
  local DURATION=$((TIMER_END - TIMER_START))
  local MIN=$((DURATION / 60))
  local SEC=$((DURATION % 60))
  if [ $MIN -gt 0 ]; then
    echo "⏱️  Completed in ${MIN}m ${SEC}s"
  else
    echo "⏱️  Completed in ${SEC}s"
  fi
}

# Check if package is installed
is_package_installed() {
  dpkg -l | grep -q "^ii.*$1 " 2>/dev/null
}

# Check if repository is configured
is_repo_configured() {
  local repo_file="$1"
  [ -f "$repo_file" ]
}

# Check if user is in group
is_user_in_group() {
  groups | grep -q "\b$1\b" 2>/dev/null
}

# Install packages with progress and checks
install_packages() {
  local packages=("$@")
  local to_install=()
  
  for package in "${packages[@]}"; do
    if is_package_installed "$package"; then
      log_success "$package is already installed"
    else
      to_install+=("$package")
    fi
  done
  
  if [ ${#to_install[@]} -eq 0 ]; then
    log_info "All packages are already installed"
    return 0
  fi
  
  log_info "Installing ${#to_install[@]} package(s)..."
  sudo apt install -y "${to_install[@]}" 2>&1 | while IFS= read -r line; do
    echo "$line"
  done
}

# Download file with cache
download_with_cache() {
  local url="$1"
  local filename=$(basename "$url")
  local filepath="${DOWNLOADS_DIR}/${filename}"
  
  if [ -f "$filepath" ]; then
    log_success "Using cached file: $filename"
    echo "$filepath"
    return 0
  fi
  
  log_info "Downloading: $filename"
  if wget -q --show-progress -O "$filepath" "$url"; then
    log_success "Downloaded: $filename"
    echo "$filepath"
  else
    log_error "Failed to download: $filename"
    return 1
  fi
}

# Main installation script
main() {
  echo "🚀 Starting installation process..."
  echo ""
  
  # Update package list once at the beginning
  log_info "Updating package list..."
  start_timer
  sudo apt update
  end_timer
  echo ""
  
  # Install essential packages
  echo "🚀 Installing essential system packages..."
  start_timer
  install_packages \
    apt-transport-https \
    build-essential \
    ca-certificates \
    curl \
    file \
    flameshot \
    gparted \
    git-all \
    gnupg \
    htop \
    libbz2-dev \
    libffi-dev \
    libfuse2 \
    liblzma-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libxmlsec1-dev \
    make \
    procps \
    silversearcher-ag \
    solaar \
    tk-dev \
    vim \
    xz-utils \
    zlib1g-dev \
    zsh
  end_timer
  echo ""
  
  # Remove unused packages
  echo "🧹 Removing unused packages..."
  start_timer
  sudo apt autoremove -y
  end_timer
  echo ""
  
  # Configure Docker permissions
  echo "🔐 Configuring Docker permissions..."
  start_timer
  if ! getent group docker > /dev/null; then
    sudo groupadd docker
    log_info "Docker group created"
  else
    log_success "Docker group already exists"
  fi
  
  if is_user_in_group "docker"; then
    log_success "User is already in docker group"
  else
    sudo usermod -aG docker "$USER"
    log_info "User added to docker group (requires logout/login to take effect)"
  fi
  end_timer
  echo ""
  
  # Configure Git
  echo "⚙️ Configuring Git (user and email)..."
  start_timer
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  log_success "Git configured"
  end_timer
  echo ""
  
  # Generate SSH key
  if [ "$SKIP_SSH_KEY_GENERATION" = false ]; then
    echo "🔑 Generating SSH key (ed25519)..."
    start_timer
    if [ ! -f ~/.ssh/id_ed25519 ]; then
      mkdir -p ~/.ssh
      ssh-keygen -t ed25519 -C "$SSH_KEY_EMAIL" -f ~/.ssh/id_ed25519 -N ""
      ssh-add ~/.ssh/id_ed25519
      log_success "SSH key generated"
    else
      log_success "SSH key already exists"
    fi
    end_timer
    echo ""
  else
    log_info "Skipping SSH key generation"
  fi
  
  # Configure GitHub CLI repository
  echo "🐙 Configuring GitHub CLI repository..."
  start_timer
  if is_repo_configured "/etc/apt/sources.list.d/github-cli.list"; then
    log_success "GitHub CLI repository already configured"
  else
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
      sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    log_success "GitHub CLI repository configured"
  fi
  end_timer
  echo ""
  
  # Configure Docker repository
  echo "🐳 Configuring Docker repository..."
  start_timer
  if is_repo_configured "/etc/apt/sources.list.d/docker.list"; then
    log_success "Docker repository already configured"
  else
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    log_success "Docker repository configured"
  fi
  end_timer
  echo ""
  
  # Configure Kubernetes repository
  echo "☸️ Configuring Kubernetes repository..."
  start_timer
  if is_repo_configured "/etc/apt/sources.list.d/kubernetes.list"; then
    log_success "Kubernetes repository already configured"
  else
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | \
      sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | \
      sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
    log_success "Kubernetes repository configured"
  fi
  end_timer
  echo ""
  
  # Configure uLauncher repository
  echo "⚙️ Configuring uLauncher repository..."
  start_timer
  if grep -rq "agornostal/ulauncher" /etc/apt/sources.list.d/ 2>/dev/null; then
    log_success "uLauncher repository already configured"
  else
    sudo add-apt-repository universe -y
    sudo add-apt-repository ppa:agornostal/ulauncher -y
    log_success "uLauncher repository configured"
  fi
  end_timer
  echo ""
  
  # Configure Antigravity repository
  echo "⚙️ Configuring Antigravity repository..."
  start_timer
  if is_repo_configured "/etc/apt/sources.list.d/antigravity.list"; then
    log_success "Antigravity repository already configured"
  else
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
      sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
      sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null
    log_success "Antigravity repository configured"
  fi
  end_timer
  echo ""
  
  # Update package list after adding repositories
  log_info "Updating package list after repository configuration..."
  sudo apt update
  echo ""
  
  # Install main tools and applications
  echo "📦 Installing main tools and applications..."
  start_timer
  install_packages \
    antigravity \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    gh \
    kubectl \
    ulauncher
  end_timer
  echo ""
  
  # Remove unused packages again
  sudo apt autoremove -y
  echo ""
  
  # GitHub login and SSH key configuration
  if [ "$SKIP_GITHUB_LOGIN" = false ]; then
    echo "🔐 Logging into GitHub and configuring SSH key..."
    start_timer
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
      log_success "Already logged into GitHub"
    else
      log_info "Please complete GitHub authentication..."
      gh auth login
      gh auth refresh -h github.com -s admin:public_key
    fi
    
    if [ -f ~/.ssh/id_ed25519.pub ]; then
      gh ssh-key add ~/.ssh/id_ed25519.pub --title "$SSH_KEY_TITLE" 2>/dev/null || \
        log_warning "SSH key may already be added to GitHub"
    fi
    end_timer
    echo ""
  else
    log_info "Skipping GitHub login"
  fi
  
  # Install Oh My Zsh
  echo "⚡ Installing Oh My Zsh..."
  start_timer
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh is already installed"
  else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
  fi
  end_timer
  echo ""
  
  # Install Google Chrome
  echo "🌐 Installing Google Chrome..."
  start_timer
  if is_package_installed "google-chrome-stable" || command -v google-chrome &> /dev/null; then
    log_success "Google Chrome is already installed"
  else
    local chrome_url="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    local chrome_filename=$(basename "$chrome_url")
    local chrome_file="${DOWNLOADS_DIR}/${chrome_filename}"
    
    # Check if already downloaded before downloading
    if [ -f "$chrome_file" ]; then
      log_info "Using cached Chrome installer"
    else
      log_info "Downloading Google Chrome..."
      chrome_file=$(download_with_cache "$chrome_url")
    fi
    
    if [ -n "$chrome_file" ] && [ -f "$chrome_file" ]; then
      log_info "Installing Google Chrome..."
      sudo dpkg -i "$chrome_file" || sudo apt-get install -f -y
      log_success "Google Chrome installed"
    else
      log_error "Failed to download or find Chrome installer"
    fi
  fi
  end_timer
  echo ""
  
  # Install JetBrains Toolbox
  echo "💡 Installing JetBrains Toolbox..."
  start_timer
  if [ -d "$HOME/.local/share/JetBrains/Toolbox" ] || command -v jetbrains-toolbox &> /dev/null; then
    log_success "JetBrains Toolbox is already installed"
  else
    curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash
    log_success "JetBrains Toolbox installed"
  fi
  end_timer
  echo ""
  
  # Install Homebrew
  echo "🍺 Installing Homebrew..."
  start_timer
  if command -v brew &> /dev/null; then
    log_success "Homebrew is already installed"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/null
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    log_success "Homebrew installed"
  fi
  end_timer
  echo ""
  
  # Install Snap applications
  echo "📱 Installing applications via Snap..."
  start_timer
  if ! command -v snap &> /dev/null; then
    log_warning "Snap is not installed, skipping snap applications"
  else
    local snap_packages=(
      beekeeper-studio
      discord
      insomnia
      postman
      slack
      spotify
      teams-for-linux
      telegram-desktop
      vlc
      zoom-client
    )
    
    for package in "${snap_packages[@]}"; do
      if snap list "$package" &> /dev/null; then
        log_success "$package is already installed"
      else
        log_info "Installing $package..."
        if [[ "$package" =~ ^(discord|slack|spotify|telegram-desktop|vlc|zoom-client)$ ]]; then
          snap install "$package" --classic 2>/dev/null || snap install "$package"
        else
          snap install "$package"
        fi
      fi
    done
  fi
  end_timer
  echo ""
  
  # Install development tools via Homebrew
  echo "🍺 Installing development tools via Homebrew..."
  start_timer
  if command -v brew &> /dev/null; then
    local brew_packages=(node nvm pnpm)
    for package in "${brew_packages[@]}"; do
      if brew list "$package" &> /dev/null; then
        log_success "$package is already installed"
      else
        log_info "Installing $package..."
        brew install "$package"
      fi
    done
  else
    log_warning "Homebrew is not installed, skipping brew packages"
  fi
  end_timer
  echo ""
  
  echo "🎉 Installation completed successfully!"
}

# Run main function
main "$@"
