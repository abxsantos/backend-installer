#!/bin/bash

get_latest_release() {
    # Retrieves the latest release version of a github repsitory
    curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
        grep -Po '"tag_name": "\K.*?(?=")'                                          # Get tag line
}

get_latest_tag() {
    # Retrieves the latest version tag of a github repsitory
    curl "https://api.github.com/repos/$1/tags" |
      grep -Po '"name": "\K.*?(?=")' | 
      head -1                          # Get first tag from GitHub api
}

BOLD="$(tput bold 2>/dev/null || printf '')"
GREY="$(tput setaf 0 2>/dev/null || printf '')"
UNDERLINE="$(tput smul 2>/dev/null || printf '')"
RED="$(tput setaf 1 2>/dev/null || printf '')"
GREEN="$(tput setaf 2 2>/dev/null || printf '')"
YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
BLUE="$(tput setaf 4 2>/dev/null || printf '')"
MAGENTA="$(tput setaf 5 2>/dev/null || printf '')"
NO_COLOR="$(tput sgr0 2>/dev/null || printf '')"

info() {
  printf '%s\n' "${BOLD}${GREY}>${NO_COLOR} $*"
}

warn() {
  printf '%s\n' "${YELLOW}! $*${NO_COLOR}"
}

error() {
  printf '%s\n' "${RED}x $*${NO_COLOR}" >&2
}

completed() {
  printf '%s\n' "${GREEN}✓${NO_COLOR} $*"
}


if [ "$EUID" -ne 0 ]
  then warn "Please run as root"
  exit
else
  echo "Start installation process"
  sudo apt-get update
  completed "Updated package manager"
  sudo apt-get install build-essential file
  
  read -p "Do you want to install cURL? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo apt-get install curl
          completed "Installed cURL";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install xclip? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo apt-get install xclip
          completed "Installed xclip";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install git? [y/n] " choice
  case "$choice" in 
    y|Y ) add-apt-repository ppa:git-core/ppa
          sudo apt-get update
          sudo apt install git
          echo "###########################"
          git --version
          completed "Installed git"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac
  
  read -p "Do you want to install homebrew? [y/n] " choice
  case "$choice" in 
    y|Y ) /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
          completed "Installed homebrew";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to add a SSH key? [y/n] " choice
  case "$choice" in 
    y|Y ) read -r -p "What is your email for SSH key generation?" GIT_SSH_KEY
          ssh-keygen -t ed25519 -C $GIT_SSH_KEY
          eval "$(ssh-agent -s)"
          ssh-add ~/.ssh/id_ed25519
          completed "Added a SSH key!"
          xclip -selection clipboard < ~/.ssh/id_ed25519.pub
          echo "###########################"
          completed "Added SSH key to clipboard!"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Docker? [y/n] " choice
  case "$choice" in 
    y|Y ) curl -fsSL https://get.docker.com -o get-docker.sh
          sh get-docker.sh
          rm -rf get-docker.sh
          sudo groupadd docker
          sudo usermod -aG docker $USER
          echo "###########################"
          docker --version
          completed "Installed Docker"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Docker Machine? [y/n] " choice
  case "$choice" in 
    y|Y ) DOCKER_MACHINE_VERSION=`get_latest_release "docker/machine"`
          curl -L "https://github.com/docker/machine/releases/download/${DOCKER_MACHINE_VERSION}/docker-machine-$(uname -s)-$(uname -m)" >/usr/local/bin/docker-machine
          sudo chmod +x /usr/local/bin/docker-machine
          echo "###########################"
          docker-machine --version
          completed "Installed Docker Machine"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Docker Compose? [y/n] " choice
  case "$choice" in 
    y|Y ) DOCKER_COMPOSE_VERSION=`get_latest_release "docker/compose"`
          curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" >/usr/local/bin/docker-compose
          sudo chmod +x /usr/local/bin/docker-compose
          echo "###########################"
          docker-compose --version
          completed "Installed Docker Compose"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install microk8s? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install microk8s --classic
          echo "###########################"
          microk8s ctr version
          completed "Installed microk8s"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac
 
  read -p "Do you want to install VS Code? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install --classic code
          code --install-extension ms-vscode-remote.remote-containers
          code --install-extension PKief.material-icon-theme
          code --install-extension VisualStudioExptTeam.vscodeintellicode
          echo "###########################"
          code --version
          completed "Installed VSCode"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install asdf? [y/n] " choice
  case "$choice" in 
    y|Y ) ASDF_VERSION=`get_latest_tag "asdf-vm/asdf"`
          git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch ${ASDF_VERSION}
          source "/home/${USER}/.bashrc"
          asdf plugin-add python
          asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
          bash -c '${ASDF_DATA_DIR:=$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring'
          echo "###########################"
          asdf --version
          completed "Installed asdf"
          echo "###########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install PyCharm Professional? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install pycharm-professional --classic
          echo "###################################"
          completed "Installed Pycharm Professional"
          echo "###################################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install WebStorm? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install webstorm --classic
          echo "########################"
          completed "Installed Webstorm"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install DBeaver CE? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install dbeaver-ce
          echo "##########################"
          completed "Installed DBeaver CE"
          echo "##########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Postman? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install postman
          echo "##########################"
          completed "Installed Postman"
          echo "##########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Insomnia? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install insomnia
          echo "########################"
          completed "Installed Insomnia"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac
  
  read -p "Do you want to install aws-cli? [y/n] " choice
  case "$choice" in 
    y|Y ) curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
          unzip awscliv2.zip
          sudo ./aws/install
          rm -rf awscliv2.zip
          rm -rf aws
          aws configure
          echo "########################"
          aws --version
          completed "Installed AWS-CLI"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac
  
  read -p "Do you want to install Slack? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install slack --classic
          echo "########################"
          completed "Installed Slack"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Flameshot? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install flameshot
          echo "########################"
          completed "Installed Flameshot"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Drawing? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install drawing
          echo "########################"
          completed "Installed Flameshot"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac

  read -p "Do you want to install Sublime Merge? [y/n] " choice
  case "$choice" in 
    y|Y ) sudo snap install sublime-merge --classic
          echo "########################"
          completed "Installed Sublime Merge"
          echo "########################";;
    n|N ) error "no";;
    * ) error "invalid";;
  esac
  
  completed "Installation ended!"
fi
