#!/bin/bash
set -uEo pipefail
# sudo curl -fsSL https://raw.githubusercontent.com/awkirin/awk-snippets/refs/heads/main/wsl/init.sh | bash

TZ=${TZ:-"Europe/Moscow"}
USER_NAME=${USER_NAME:-"awkirin"}
USER_EMAIL=${USER_EMAIL:-"awkirin@gmail.com"}
USER_HOME=$(eval echo "~${USER_NAME}")
IS_WSL=$(grep -qiE "(Microsoft|WSL)" /proc/version && echo 1 || echo 0)

export DEBIAN_FRONTEND=noninteractive # Чтобы исключить зависание.
sudo timedatectl set-timezone "${TZ}"

function log_info() {
    local msg="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "\033[1;32m[INFO] [$timestamp]\033[0m $msg ================================================================="
}


function config_apt() {
  log_info ""
  sudo tee /etc/apt/apt.conf.d/80-retries > /dev/null <<EOF
Acquire::Retries "5";
EOF

  function add_yandex_mirrors() {
    log_info "add apt yandex mirrors"
    sudo tee /etc/apt/sources.list.d/1000-yandex.list > /dev/null <<EOF
deb https://mirror.yandex.ru/ubuntu/ $(lsb_release -cs) main restricted universe multiverse
deb https://mirror.yandex.ru/ubuntu/ $(lsb_release -cs)-updates main restricted universe multiverse
deb https://mirror.yandex.ru/ubuntu/ $(lsb_release -cs)-backports main restricted universe multiverse
deb https://mirror.yandex.ru/ubuntu/ $(lsb_release -cs)-security main restricted universe multiverse
EOF
  }; yandex_mirrors

  log_info ""
  sudo add-apt-repository ppa:graphics-drivers/ppa

  log_info ""
  sudo add-apt-repository ppa:videolan/stable-daily
}; config_apt

sudo apt update -y #&& sudo apt upgrade -y #&& sudo apt full-upgrade -y
sudo apt install -y ca-certificates build-essential coreutils gnupg net-tools dnsutils curl wget openssh-client git gh zip unzip age jq fzf htop zsh ansible nautilus

function install_extrepo() {
  sudo apt update -y
  sudo apt install -y extrepo extrepo-offline-data
  sudo sed -i 's/# - contrib/- contrib/' /etc/extrepo/config.yaml
  sudo sed -i 's/# - non-free/- non-free/' /etc/extrepo/config.yaml
  EXTREPOS=(
    google_chrome
    brave_release
    torproject
    signal
    element.io
    docker-ce
    kubernetes
    hashicorp
    vscode
    virtualbox
    helm
    anydesk
    tailscale
    nvidia-docker
  )
  for repo in "${EXTREPOS[@]}"; do
      sudo extrepo enable "$repo"
  done
  sudo apt update -y
}; install_extrepo

function install_git() {
  log_info "git"
  sudo -u "${USER_NAME}" tee "${USER_HOME}"/.gitconfig > /dev/null <<EOF
[user]
  name = ${USER_NAME}
  email = ${USER_EMAIL}
[init]
  defaultBranch = main
[core]
  autocrlf = input
  quotepath = false
[pull]
  rebase = false
[push]
  default = simple
  autoSetupRemote = true
[color]
  ui = auto
EOF
}; install_git
function install_ohmyzsh() {
  log_info "install oh-my-zsh"
  sudo apt install zsh -y
  sudo -u "${USER_NAME}" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  sudo chsh -s "$(which zsh)" "${USER_NAME}"

  log_info "install plugins"
  sudo -u "${USER_NAME}" git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  sudo -u "${USER_NAME}" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

  log_info "custom config oh-my-zsh"
  sudo -u "${USER_NAME}" tee "$USER_HOME/.zshrc-custom" > /dev/null <<EOF
plugins=(
z
sudo
dotenv
git-auto-fetch
brew
fzf
command-not-found
colored-man-pages
ssh-agent
history
history-substring-search
common-aliases
zsh-autosuggestions
zsh-syntax-highlighting
)
EOF
  sudo -u "${USER_NAME}" sed -i '/^plugins=/c\source $HOME/.zshrc-custom' ~/.zshrc

  if [[ "$IS_WSL" -eq 1 ]]; then
    log_info "wsl2-ssh-agent"
    sudo -u "${USER_NAME}" tee "$USER_HOME/.oh-my-zsh/custom/wsl2-ssh-agent.zsh" > /dev/null <<EOF
eval $(wsl2-ssh-agent)
EOF
  fi
}; install_ohmyzsh
function install_xrdp() {
  sudo apt install xrdp -y

  if [[ "$IS_WSL" -eq 1 ]]; then
    if [[ ! -f "/etc/xrdp/xrdp.ini.bak" ]]; then
      sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
    fi
    sudo sed -i 's/3389/3390/g' /etc/xrdp/xrdp.ini
    sudo sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini
    sudo sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini

    # sudo apt install ubuntu-desktop -y
    sudo tee ~/.xsessionrc > /dev/null <<EOF
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
export XDG_DATA_DIRS=/usr/share/ubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop
export WAYLAND_DISPLAY=
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg
EOF

    sudo systemctl restart xrdp
  fi
}; #install_xrdp

if [[ "$IS_WSL" -eq 0 ]]; then
  function install_yandex_disk() {
    curl -fsSL https://repo.yandex.ru/yandex-disk/YANDEX-DISK-KEY.GPG \
      | gpg --dearmor | sudo tee /usr/share/keyrings/yandex-disk.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/yandex-disk.gpg] https://repo.yandex.ru/yandex-disk/deb/ stable main" \
      | sudo tee /etc/apt/sources.list.d/yandex-disk.list > /dev/null
    sudo apt update -y
    sudo apt install -y yandex-disk
  }; install_yandex_disk
  function install_keepassxc() {
    log_info "keepassxc"
    sudo add-apt-repository -y ppa:phoerious/keepassxc
    sudo apt update -y
    sudo apt install -y keepassxc
  }; install_keepassxc
  function install_google_chrome() {
    log_info "google-chrome"
#    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
#      | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg > /dev/null
#    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
#      | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
#    sudo apt update -y
    sudo apt install -y google-chrome-stable
  }; install_google_chrome
  function install_docker() {
    log_info "docker"
    sudo apt install -y docker
#    sudo sh -c "$(curl -fsSL get.docker.com)"
#    sudo usermod -aG docker "${USER_NAME}"
#    systemctl enable docker
#    systemctl start docker
  }; install_docker
  function install_lando() {
    if [[ "$IS_WSL" -eq 0 ]]; then
      log_info "lando"
      sudo -u "${USER_NAME}" /bin/bash -c "$(curl -fsSL get.lando.dev/setup-lando.sh) --yes"
    fi
  }; install_lando
  function install_vagrant() {
    if [[ "$IS_WSL" -eq 0 ]]; then
      log_info "vagrant"
      wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
      sudo apt update
      sudo apt install vagrant
    fi
  }; install_vagrant
fi

if [[ "$IS_WSL" -eq 1 ]]; then
  function config_wsl() {
    log_info "wsl config"
    sudo tee "/etc/wsl.conf" > /dev/null <<EOF
[boot]
systemd = true

[user]
default = ${USER_NAME}

[interop]
appendWindowsPath = false

[automount]
enabled = true
root = /mnt
options = "metadata,umask=22,fmask=11"
#mountFsTab = true
EOF
  }; config_wsl
  function install_wsl2_ssh_agent() {
    echo "install_wsl2_ssh_agent"

    log_info "wsl ssh-agent"
    WSL2_SSH_AGENT_PATH="/usr/local/bin/wsl2-ssh-agent"
    sudo curl -L -o "$WSL2_SSH_AGENT_PATH" https://github.com/mame/wsl2-ssh-agent/releases/latest/download/wsl2-ssh-agent
    sudo chmod 755 "$WSL2_SSH_AGENT_PATH"

    if [[ -f "/mnt/c/Users/$USER_NAME/.ssh/config" ]]; then
      log_info "wsl ssh config"
      mkdir -p "$USER_HOME/.ssh"
      cp "/mnt/c/Users/$USER_NAME/.ssh/config" "$USER_HOME/.ssh/config" 2>/dev/null || true
      chmod 700 "$USER_HOME/.ssh"
      chmod 600 "$USER_HOME/.ssh/config" 2>/dev/null || true
    fi
  }; install_wsl2_ssh_agent
fi

sudo apt autoremove -y && sudo apt autoclean -y && sudo apt clean



function install_brew() {
  echo "brew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"

  echo "install gcc"
  brew install gcc
}; install_brew
function install_sops() {
  log_info "sops"
  brew install sops
#  SOPS_LATEST_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | jq -r ".tag_name")
#  sudo curl -L -o /usr/local/bin/sops "https://github.com/getsops/sops/releases/download/$SOPS_LATEST_VERSION/sops-$SOPS_LATEST_VERSION.linux.amd64"
#  sudo chmod +x /usr/local/bin/sops

  if [[ "$IS_WSL" -eq 1 ]]; then
    if [[ -f "/mnt/c/Users/$USER_NAME/.config/sops/age/keys.txt" ]]; then
      mkdir -p "$USER_HOME/.config/sops/age"
      cp "/mnt/c/Users/$USER_NAME/.config/sops/age/keys.txt" "$USER_HOME/.config/sops/age/keys.txt" 2>/dev/null || true
      chmod 700 "$USER_HOME/.config/sops"
      chmod 600 "$USER_HOME/.config/sops/age/keys.txt" 2>/dev/null || true
    fi
  fi
}; install_sops
function install_nvm() {
    brew install nvm
    sudo -u "${USER_NAME}" tee "$USER_HOME/.oh-my-zsh/custom/nvm.zsh" > /dev/null <<EOF
export NVM_DIR="$HOME/.nvm"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
    [ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
EOF
  source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
}; install_nvm
function install_node() {
    nvm install --lts
    corepack enable yarn
    corepack enable pnpm
}; install_node

log_info "end"
