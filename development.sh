#!/bin/bash

#set -e
#set -x	#	debug

WSL=`uname -v | grep Microsoft`

export SERVER="Y"
export DOCKER="Y"

export CONF_PATH=/root/config
export CONF_BACKUP=/root/.config-backup
export LOCAL_ADMIN_PATH=~/.bin-admin
export LOCAL_CONF_PATH=$LOCAL_ADMIN_PATH/config

echo "Installing System Services..."

if [[ -z "`which sudo`" ]] ; then
	apt update
	apt install -y sudo
else
	sudo apt update
fi

if [[ ! -e "$CONF_BACKUP" ]] ; then
	sudo mkdir -p $CONF_BACKUP
fi

if [[ ! -e "$CONF_PATH" ]] ; then
	if [[ ! -d "$LOCAL_ADMIN_PATH" ]] ; then
		echo "WARN: $LOCAL_CONF_PATH and $CONF_PATH NOT exist..."
		./cp_to_admin.sh
		#exit 1
	fi
	sudo cp -a $LOCAL_CONF_PATH $CONF_PATH
fi

# Base: ssh, git, make, vim, cscope, ctags, ag, ack
./script/base.sh

# VCS
#sudo apt install -y gitk
#sudo apt install -q -y subversion

if [[ -z "$WSL" ]] ; then
	# APM
	./script/apm.sh

	# Samba
	./script/samba.sh

	# FTP / TFTP
	./script/ftp.sh
	./script/tftp.sh

	# NFS
	./script/nfs.sh

	# for ubuntu desktop...
	if [[ "$SERVER" != "Y" ]] ; then
		./script/desktop.sh
	fi

	# Docker
	if [[ "$DOCKER" = "Y" ]] ; then
		./script/docker.sh
	fi
else
# for Windows WSL
	# FTP
	./script/ftp.sh

	#	start SSH daemon for WSL
	sudo cp -a --backup=numbered /etc/ssh/sshd_config $CONF_BACKUP
	sudo cp -a $CONF_PATH/sshd_config-wsl /etc/ssh/sshd_config
	echo "$USER ALL=(root) NOPASSWD: /usr/sbin/sshd" | sudo tee -a /etc/sudoers
	echo "$USER ALL=(root) NOPASSWD: /usr/sbin/vsftpd" | sudo tee -a /etc/sudoers

	sudo systemd-machine-id-setup
	sudo dbus-uuidgen --ensure
	cat /etc/machine-id

	sudo apt -y install x11-apps xfonts-base xfonts-100dpi xfonts-75dpi xfonts-cyrillic

	sudo apt -y install language-pack-ko
	sudo locale-gen ko_KR.UTF-8
	sudo apt -y install fonts-unfonts-core fonts-unfonts-extra
	sudo apt -y install fonts-baekmuk fonts-nanum fonts-nanum-coding fonts-nanum-extra
fi	#	WSL

#exit 0

echo "Installing Development Tools for gcc..."

# for Development
sudo dpkg --add-architecture i386
sudo apt install -y build-essential

sudo apt install -y gcc-multilib g++-multilib

# for compiling kernel( menuconfig )
sudo apt install -y ncurses-dev libssl-dev

sudo cp -a --backup=numbered /etc/profile $CONF_BACKUP/etc_profile
sudo cp -a $CONF_PATH/etc_profile /etc/profile

# Remote Desktop
if [[ "$SERVER" = "Y" ]] ; then
	./script/xrdp.sh
fi

# Clean apt packages and cache
#sudo apt clean && sudo apt autoremove
#sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#sudo apt install libpython2.7-dev
#\~/.vim/bundle/YouCompleteMe/install.sh --clang-completer

service --status-all
