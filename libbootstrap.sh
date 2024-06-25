#!/bin/bash

### BEGIN HELPERS ###

function WriteTaskName {
	echo "TASK: ${FUNCNAME[1]}"
}

function NvidiaCheck {
	nvidiaHardwareCheck=$(lspci | grep NVIDIA | awk -F: '{print $NF}')
	if [ "$nvidiaHardwareCheck" == "" ]; then
		return 1
	fi
}

function EnableFlathubRepo {
	flathubCheck=$(sudo flatpak remotes | grep flathub)
	if [ "$flathubCheck" != "" ]; then
		return 0
	fi

	sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
	echo "...Flathub repository added"
}

function VirtManagerCheck {
	lscpuCheck=$(lscpu | grep VT-x)
	if [ "$lscpuCheck" == "" ]; then
		return 1
	fi

	uname=$(uname -r)
	zgrepCheck=$(zgrep CONFIG_KVM /boot/config-"$uname" | grep "CONFIG_KVM_GUEST=y")
	if [ "$zgrepCheck" == "" ]; then
		return 1
	fi
}

function ConfigureVirtManager {
	# Ensure libvirtd and tuned services are enabled
	# This service will not stay running if in a VM, so only do this part if no VM detected
	vmCheck=$(grep hypervisor </proc/cpuinfo)

	libvirtdCheck=$(sudo systemctl is-active libvirtd.service)
	if [ "$vmCheck" == "" ] && [ "$libvirtdCheck" == "inactive" ]; then
		sudo systemctl enable --now libvirtd.service
		echo "...libvirtd service enabled"
	fi

	tunedCheck=$(sudo systemctl is-active tuned.service)
	if [ "$tunedCheck" == "inactive" ]; then
		sudo systemctl enable --now tuned.service
		echo "...tuned service enabled"
	fi

	# Set autostart on virtual network
	virshNetworkCheck=$(sudo virsh net-list --all --autostart | grep default)
	if [ "$virshNetworkCheck" == "" ]; then
		sudo virsh net-autostart default
		echo "...Virtual network set to autostart"
	fi

	# Add regular user to libvirt group
	groupCheck=$(groups "$USER" | grep libvirt)
	if [ "$groupCheck" == "" ]; then
		sudo usermod -aG libvirt "$USER"
		echo "...User added to libvirt group"
	fi
}

### END HELPERS ###

### BEGIN TASKS ###

function CreateDirectories {
	WriteTaskName

	directories=(
		"$HOME/repos"
		"$HOME/repos/theming"
		"$HOME/Pictures"
		"$HOME/Pictures/wallpapers"
		"$HOME/.cache"
		"$HOME/.local"
		"$HOME/.local/bin"
		"$HOME/.local/share"
		"$HOME/.local/share/fonts"
		"$HOME/.local/share/icons"
		"$HOME/.themes"
	)

	for directory in "${directories[@]}"; do
		if [ ! -d "$directory" ]; then
			mkdir "$directory"
			echo "...Created $directory"
		fi
	done
}

function ConfigureTmux {
	WriteTaskName

	# Oh My Tmux
	ohMyTmuxPath="$HOME/.tmux"
	if [ ! -d "$ohMyTmuxPath" ]; then
		echo "...Installing Oh My Tmux"

		git clone https://github.com/gpakosz/.tmux.git "$ohMyTmuxPath"
		ln -sf "$ohMyTmuxPath"/.tmux.conf "$HOME"/.tmux.conf
		cp "$ohMyTmuxPath"/.tmux.conf.local "$HOME"/

		echo "...Successfully installed Oh My Tmux"
	fi

	# Ensure Tmux is fully configured, exit if not
	# Check for commented out mouse mode as the check, the default config has this
	if grep -Fxq "#set -g mouse on" "$HOME"/.tmux.conf.local; then
		echo "...WARNING: Oh My Tmux still needs to be configured"
	fi
}

function InstallNvm {
	WriteTaskName

	if [ ! -d "$HOME"/.nvm ]; then
		wget -O- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
		echo "...nvm installed"
	fi
}

function ConfigureZsh {
	WriteTaskName

	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		echo "...Installing Oh My Zsh, you will be dropped into a new zsh session at the end"
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
}

function InstallNerdFonts {
	WriteTaskName

	localFontsDir="$HOME/.local/share/fonts"

	firaCodeNerdFontCheck="$localFontsDir/FiraCodeNerdFont-Regular.ttf"
	if [ ! -f "$firaCodeNerdFontCheck" ]; then
		echo "...Installing FiraCode Nerd Font"
		curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -o fira.zip
		unar -d fira.zip
		cp fira/*.ttf "$localFontsDir"
		rm -r fira
		rm fira.zip
		echo "...FiraCode Nerd Font installed"
	fi

	ubuntuNerdFontCheck="$localFontsDir/UbuntuNerdFont-Regular.ttf"
	if [ ! -f "$ubuntuNerdFontCheck" ]; then
		echo "...Installing Ubuntu Nerd Font"
		curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Ubuntu.zip -o ubuntu.zip
		unar -d ubuntu.zip
		cp ubuntu/*.ttf "$localFontsDir"
		rm -r ubuntu
		rm ubuntu.zip
		echo "...Ubuntu Nerd Font installed"
	fi

	ubuntuMonoNerdFontCheck="$localFontsDir/UbuntuMonoNerdFont-Regular.ttf"
	if [ ! -f "$ubuntuMonoNerdFontCheck" ]; then
		echo "...Installing UbuntuMono Nerd Font"
		curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip -o ubuntumono.zip
		unar -d ubuntumono.zip
		cp ubuntumono/*.ttf "$localFontsDir" &>/dev/null
		rm -r ubuntumono
		rm ubuntumono.zip
		echo "...UbuntuMono Nerd Font installed"
	fi
}

function DownloadCatppuccinTheme {
	WriteTaskName

	# GTK + icons
	accentColors=(
		"blue"
		"flamingo"
		"green"
		"lavender"
		"maroon"
		"mauve"
		"peach"
		"pink"
		"red"
		"rosewater"
		"sapphire"
		"sky"
		"teal"
		"yellow"
	)

	for accentColor in "${accentColors[@]}"; do

		if [ ! -d "$HOME"/.themes/catppuccin-mocha-"$accentColor"-standard+default ]; then
			wget https://github.com/catppuccin/gtk/releases/latest/download/catppuccin-mocha-"$accentColor"-standard+default.zip
			unar -d catppuccin-mocha-"$accentColor"-standard+default.zip
			mv catppuccin-mocha-"$accentColor"-standard+default/catppuccin-mocha-"$accentColor"-standard+default "$HOME"/.themes
			rm -rf catppuccin-mocha-"$accentColor"-standard+default
			rm -f catppuccin-mocha-"$accentColor"-standard+default.zip
			echo "...Installed Catppuccin GTK Mocha $accentColor theme"
		fi

	done

	if [ ! -d "$HOME"/.local/share/icons/Tela-circle-dark ]; then
		mkdir "$HOME"/repos/theming/Tela-circle-dark
		git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git "$HOME"/repos/theming/Tela-circle-dark
		"$HOME"/repos/theming/Tela-circle-dark/install.sh -a -c -d "$HOME"/.local/share/icons
		echo "...Installed Tela-circle icon themes"
	fi

	# Ulauncher
	if ! compgen -G "$HOME/.config/ulauncher/user-themes/Catppuccin-Mocha*" >/dev/null; then
		python3 <(curl https://raw.githubusercontent.com/catppuccin/ulauncher/main/install.py -fsSL) -f all -a all &>/dev/null
		echo "...Installed Ulauncher Catppuccin themes"
	fi

	# Grub
	if [ ! -d /usr/share/grub/themes ]; then
		sudo mkdir /usr/share/grub/themes
		echo "...Created grub themes directory"
	fi

	if [ ! -d /usr/share/grub/themes/catppuccin-mocha-grub-theme ]; then
		mkdir "$HOME"/repos/theming/catppuccin-grub
		git clone https://github.com/catppuccin/grub.git "$HOME"/repos/theming/catppuccin-grub
		sudo cp -r "$HOME"/repos/theming/catppuccin-grub/src/catppuccin-mocha-grub-theme /usr/share/grub/themes
		echo "...Installed Catppuccin grub theme to themes directory"
	fi

	grubThemeCheck=$(grep "/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt" </etc/default/grub)
	if [ "$grubThemeCheck" == "" ]; then
		echo "...NOTE: Set grub theme by adding GRUB_THEME=\"/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt\" to /etc/default/grub, then running update-grub"
	fi

	# Wallpapers
	if [ ! -d "$HOME"/Pictures/wallpapers/catppuccin ]; then
		echo "...Installing Catppuccin wallpaper pack"
		mkdir "$HOME"/Pictures/wallpapers/catppuccin
		mkdir "$HOME"/repos/theming/catppuccin-wallpapers
		git clone https://github.com/Gingeh/wallpapers.git "$HOME"/repos/theming/catppuccin-wallpapers
		cp -r "$HOME"/repos/theming/catppuccin-wallpapers/*/*.png "$HOME"/Pictures/wallpapers/catppuccin
		cp -r "$HOME"/repos/theming/catppuccin-wallpapers/*/*.jpg "$HOME"/Pictures/wallpapers/catppuccin
		echo "...Catppuccin wallpaper pack installed"
	fi

	# Tmux
	if ! grep -Fxq "set -g @plugin 'catppuccin/tmux'" "$HOME"/.tmux.conf.local; then
		echo "NOTE: Set tmux theme by adding the following to .tmux.conf.local: set -g @plugin 'catppuccin/tmux'"
	fi
}

function InstallAws {
	WriteTaskName

	if [ ! -f "/usr/local/bin/aws" ]; then
		curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
		unzip awscliv2.zip
		sudo ./aws/install
		rm -f awscliv2.zip
		rm -rf aws
		echo "...Installed AWS CLI"
	fi
}

### END TASKS ###

### BEGIN DEPRECATED ###

#function DownloadPlankThemeCommon {
#	if [ ! -d "$HOME"/.local/share/plank ]; then
#		mkdir "$HOME"/.local/share/plank
#		echo "...Created plank directory"
#	fi
#
#	if [ ! -d "$HOME"/.local/share/plank/themes ]; then
#		mkdir "$HOME"/.local/share/plank/themes
#		echo "...Created plank themes directory"
#	fi
#
#	if [ ! -d "$HOME"/.local/share/plank/themes/Catppuccin-mocha ]; then
#		mkdir "$HOME"/repos/theming/catppuccin-plank
#		git clone https://github.com/catppuccin/plank.git "$HOME"/repos/theming/catppuccin-plank &>/dev/null
#		cp -r "$HOME"/repos/theming/catppuccin-plank/src/Catppuccin-mocha "$HOME"/.local/share/plank/themes &>/dev/null
#		echo "...Installed Catppuccin plank theme"
#	fi
#}

### END DEPRECATED ###
