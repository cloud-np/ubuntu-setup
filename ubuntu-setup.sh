#!/bin/bash

# Ubuntu System Setup Script
# This script installs 
# Rust
# nvim v0.11.0
# Nerdfonts JetBrainsMono v3.3
# Nushell v0.103.0
# fnm
# Node v23.10.0
# pnpm
# -Debian packages
#   curl wget unzip apt-transport-https gnupg 
#   software-properties-common git build-essential
#   gcc g++ make cmake tmux libssl-dev pkg-config ripgrep
#
# -Snap packages
#   Brave
#   Vlc
#   Spotify
#   Alacritty
#   WebStorm
#   Code
#   Obsidian

set -e  # Exit immediately if a command exits with a non-zero status
set -u  # Treat unset variables as an error

echo "===== Starting system setup ====="
echo "$(date)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to display section headers
section() {
    echo ""
    echo "===== $1 ====="
    echo ""
}

# Update system packages
section "Updating system packages"
sudo apt update && sudo apt upgrade -y

# Install basic dependencies
section "Installing basic dependencies"
sudo apt install -y curl wget unzip apt-transport-https gnupg software-properties-common git build-essential gcc g++ make cmake tmux libssl-dev pkg-config ripgrep

# Create temporary directory for download
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Install Rust
section "Installing Rust"
if ! command_exists rustc; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    rustc --version
    cargo --version
else
    echo "Rust is already installed"
    rustc --version
fi

# Install Nushell v0.103.0 from releases
section "Installing Nushell"
if ! command_exists nu; then

    # Nushell creates this folder, so we could our config earlier to be sure
    git clone https://github.com/cloud-np/nushell.git $HOME/.config/nushell

    # Download the Nushell package
    wget https://github.com/nushell/nushell/releases/download/0.103.0/nu-0.103.0-x86_64-unknown-linux-gnu.tar.gz

    # Extract the downloaded archive
    tar -xvzf nu-0.103.0-x86_64-unknown-linux-gnu.tar.gz

    # Move the Nushell binary to a directory in your PATH
    sudo cp nu-0.103.0-x86_64-unknown-linux-gnu/nu /usr/local/bin/

    # Make the binary executable (if needed)
    sudo chmod +x /usr/local/bin/

    # Optional: Make Nushell your default shell
    sudo sh -c "echo $(which nu) >> /etc/shells"
    chsh -s $(which nu)
else
    echo "Nushell is already installed"
fi

# Install tmux config
section "Installing tmux config"
if [ ! -d "$HOME/.config/tmux" ]; then
    git clone https://github.com/cloud-np/tmux.git $HOME/.config/tmux
else
    echo "Tmux config already exists, skipping..."
fi

# Install Neovim from GitHub releases
section "Installing Neovim"
if ! command_exists nvim; then
    
    # Get the latest stable release of Neovim
    echo "Downloading latest Neovim stable release..."
    wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
    
    # Extract and install
    echo "Extracting and installing Neovim..."
    tar xzf nvim-linux-x86_64.tar.gz
    sudo mv nvim-linux-x86_64 /opt/nvim
    
    # Create symbolic link
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim

    # Verify installation
    nvim --version
else
    echo "Neovim is already installed"
    nvim --version
fi

# Install Nerd Fonts
if [ ! -f ~/.local/share/fonts/JetBrainsMonoNerdFont-Regular.ttf ]; then
    echo "Installing Nerd Fonts..."
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip
    unzip JetBrainsMono.zip -d JetBrainsMonoFont
    mkdir -p ~/.local/share/fonts
    mv ./JetBrainsMonoFont/*.ttf ~/.local/share/fonts
    fc-cache -f -v
    # Clean up
    rm -f JetBrainsMono.zip
    rm -rf JetBrainsMonoFont
else
    echo "JetBrains Mono Nerd Font already installed, skipping..."
fi

# Install Starship
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh
else
    echo "Starship already installed, skipping..."
fi

# Clone Neovim configuration
section "Setting up Neovim configuration"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

# Backup existing config if it exists
if [ -d "$NVIM_CONFIG_DIR" ]; then
    echo "Backing up existing Neovim configuration..."
    mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d%H%M%S)"
fi

section "Installing fnm"
if ! command_exists fnm; then
    echo "Installing fnm..."
    curl -fsSL https://fnm.vercel.app/install | bash

    # Add to path to be able to install Node after
    if [ -d "$FNM_PATH" ]; then
        export PATH="$FNM_PATH:$PATH"
        eval "`fnm env`"
    fi
else
    echo "fnm is already installed"
fi

# Install Node
section "Installing Node"
echo "Installing Node v23.10.0..."
fnm install v23.10.0
echo "Installing pnpm"
npm i -g pnpm

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Clone your Neovim configuration repository
echo "Cloning Neovim configuration repository..."
git clone https://github.com/cloud-np/nvim.git "$NVIM_CONFIG_DIR"

# Clean up
cd - > /dev/null
rm -rf "$TMP_DIR"

# Install Snap packages
section "Installing Snap packages"

# Ensure snap is installed
if ! command_exists snap; then
    sudo apt install -y snapd
    sudo systemctl enable --now snapd.socket
fi

# Install Brave
echo "Installing Brave..."
if ! snap list | grep -q brave; then
    sudo snap install brave
else
    echo "Brave is already installed"
fi

# Install Vlc
echo "Installing Vlc..."
if ! snap list | grep -q vlc; then
    sudo snap install vlc
else
    echo "Vlc is already installed"
fi

# Install Spotify
echo "Installing Spotify..."
if ! snap list | grep -q spotify; then
    sudo snap install spotify
else
    echo "Spotify is already installed"
fi

# Install Alacritty terminal
echo "Installing Alacritty..."
if ! snap list | grep -q alacritty; then
    sudo snap install alacritty --classic
    # Make it default terminal
    gsettings set org.gnome.desktop.default-applications.terminal exec 'alacritty'
    # Maybe more robust
    # sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator /snap/bin/alacritty 50
    # sudo update-alternatives --config x-terminal-emulator
else
    echo "Alacritty is already installed"
fi

# Install WebStorm
echo "Installing WebStorm..."
if ! snap list | grep -q webstorm; then
    sudo snap install webstorm --classic
else
    echo "WebStorm is already installed"
fi

# Install VScode
echo "Installing VScode..."
if ! snap list | grep -q code; then
    sudo snap install code --classic
else
    echo "VScode is already installed"
fi

# Install Obsidian
echo "Installing Obsidian..."
if ! snap list | grep -q obsidian; then
    sudo snap install obsidian --classic
else
    echo "Obsidian is already installed"
fi

# Final system update
section "Final system update"
sudo apt update && sudo apt upgrade -y

section "Setup complete!"
echo "System setup completed successfully on $(date)"
echo "You may need to restart your system for all changes to take effect."

# List installed versions
section "Installed versions"
echo "Rust: $(rustc --version)"
echo "Neovim: $(nvim --version | head -n 1)"
echo "Brave: $(brave --version 2>/dev/null || echo 'Not installed')"
echo "Vlc: $(snap list | grep vlc || echo 'Not installed')"
echo "VScode: $(snap list | grep code || echo 'Not installed')"
echo "Spotify: $(snap list | grep spotify || echo 'Not installed')"
echo "Alacritty: $(snap list | grep alacritty || echo 'Not installed')"
echo "WebStorm: $(snap list | grep webstorm || echo 'Not installed')"
echo "Obsidian: $(snap list | grep obsidian || echo 'Not installed')"

