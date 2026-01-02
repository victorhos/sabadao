#!/bin/bash
set -e

echo "Start install..."
sudo apt install git-all \
	zsh \
	vim \
	curl \
	silversearcher-ag \
	libfuse2 \
	ca-certificates \
	curl \
	gnupg \
	build-essential \
	procps \
	file \
	git \
	htop \
	make \
	libssl-dev \
	zlib1g-dev \
	libbz2-dev \
	libreadline-dev \
	libsqlite3-dev \
	libncursesw5-dev \
	xz-utils \
	tk-dev \
	libxml2-dev \
	libxmlsec1-dev \
	libffi-dev \
	apt-transport-https \
	gnupg2 \
	flameshot \
    solaar \
    gparted \
	liblzma-dev -y

echo "Start autoremove..."
sudo apt autoremove -y

echo "Docker permissions..."
if ! getent group docker > /dev/null; then
  sudo groupadd docker
  sudo usermod -aG docker $USER
  newgrp docker
fi

echo "Config git..."
git config --global user.name "Victor Silva"
git config --global user.email "victor.hos@gmail.com"

echo "Generate ssh key..."
ssh-keygen -t ed25519 -C "victor.hos@gmail.com"
ssh-add ~/.ssh/id_ed25519

echo "Config GitHub client..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

echo "Config Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Config Kubernets..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

echo "Config uLauncher..."
sudo add-apt-repository universe -y && sudo add-apt-repository ppa:agornostal/ulauncher -y

echo "Config Antigravity..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | \
  sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | \
  sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

sudo apt update
echo "Install libs"
sudo apt install gh docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin kubectl ulauncher antigravity -y
sudo apt autoremove

echo "Login GitHub"
gh auth login
gh auth refresh -h github.com -s admin:public_key
gh ssh-key add ~/.ssh/id_ed25519.pub --title "desktop-ubuntu"

echo "Install OhMyZSH"
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is installed."
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Install Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb

echo "Install JetBrains"
curl -fsSL https://raw.githubusercontent.com/nagygergo/jetbrains-toolbox-install/master/jetbrains-toolbox.sh | bash

echo "Install Brew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> ~/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

echo "Snap apps"
snap install discord insomnia postman spotify vlc zoom-client teams-linus slack telegram-desktop beekeeper-studio

echo "Brew apps"
brew install node nvm pnpm
