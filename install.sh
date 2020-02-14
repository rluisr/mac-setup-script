#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  authy
  jetbrains-toolbox
  istat-menus
  slack
  alfred
  keyboard-maestro
)

brews=(
  ansible
  peco
  awscli
  "bash-snippets --without-all-tools --with-cryptocurrency --with-stocks --with-weather"
  coreutils
  findutils
  git
  git-extras
  git-fresh
  git-lfs
  "gnu-sed --with-default-names"
  go
  gpg
  ghq
  golangci-lint
  direnv
  htop
  nmap
  node
  python
  python3
  osquery
  ruby
  shellcheck
  thefuck
  tmux
  tree
  trash
  pyenv
  rbenv
  "vim --with-override-system-vi"
  "wget --with-iri"
)

casks=(
  docker
  firefox
  google-backup-and-sync
)

pips=(
  pip
  glances
  ohmu
  pythonpy
)

gems=(
  bundler
  travis
)

npms=(
  fenix-cli
  gitjk
  kill-tabs
  n
)

gpg_key='3E219504'
git_email='pathikritbhowmick@msn.com'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "remote.origin.prune true"
  "rerere.enabled true"
  "user.name pathikrit"
  "user.email ${git_email}"
  "user.signingkey ${gpg_key}"
)

JDK_VERSION=amazon-corretto@1.8.222-10.1

######################################## End of app list ########################################
set +e
set -x

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap caskroom/versions
install 'brew cask install' "${important_casks[@]}"

install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash && . ~/.jabba/jabba.sh
jabba install ${JDK_VERSION}
jabba alias default ${JDK_VERSION}
java -version

for config in "${git_configs[@]}"
do
  git config --global ${config}
done

if [[ -z "${CI}" ]]; then
  gpg --keyserver hkp://pgp.mit.edu --recv ${gpg_key}
  ssh-keygen -t rsa -b 4096 -C ${git_email}
  pbcopy < ~/.ssh/id_rsa.pub
  open https://github.com/settings/ssh/new
fi

brew install bash bash-completion2 fzf
sudo bash -c "echo $(brew --prefix)/bin/bash >> /private/etc/shells"
#sudo chsh -s "$(brew --prefix)"/bin/bash
# Install https://github.com/twolfson/sexy-bash-prompt
touch ~/.bash_profile #see https://github.com/twolfson/sexy-bash-prompt/issues/51
(cd /tmp && git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt && cd sexy-bash-prompt && make install) && source ~/.bashrc

echo "
alias del='mv -t ~/.Trash/'
alias ls='exa -l'
alias cat=bat
" >> ~/.bash_profile

sudo bash -c "which xonsh >> /private/etc/shells"
sudo chsh -s $(which xonsh)
echo "source-bash --overwrite-aliases ~/.bash_profile" >> ~/.xonshrc

install 'brew cask install' "${casks[@]}"

install 'pip3 install --upgrade' "${pips[@]}"
install 'gem install' "${gems[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

cd ~/Downloads
git clone https://github.com/LanikSJ/slack-dark-mode
cd slack-dark-mode
./slack-dark-mode.sh 

pip3 install --upgrade pip setuptools wheel
if [[ -z "${CI}" ]]; then
  m update install all
fi

if [[ -z "${CI}" ]]; then
  mas list
fi

brew cleanup
brew cask cleanup

echo "Run [mackup restore] after DropBox has done syncing ..."
echo "Done!"
