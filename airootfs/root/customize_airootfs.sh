#!/bin/bash

set -e -u

# Encoding
sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
sed -i 's/#\(fr_FR\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

# localtime
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

# configure root
usermod -s /usr/bin/zsh root
# chmod 700 /root

# Keyboard
loadkeys fr

# GIve liveuser adminrights
groupadd sudo
sed -i 's/# \(%sudo\tALL=(ALL) ALL\)/\1/' /etc/sudoers

# Create user
useradd -m -p "" -g users -G "sudo,adm,audio,floppy,log,network,rfkill,scanner,storage,optical,power,wheel" -s /usr/bin/zsh liveuser
cp -aT /etc/skel/ /home/liveuser
chown liveuser:users /home/liveuser -R

# Add configuration from git
bck_dir=$(pwd)
cd /home/liveuser
git init
git remote add origin https://github.com/galaunay/config
git remote update
git clean -f
git checkout master
git submodule update --init --recursive
chown -R liveuser:users /home/liveuser
cd $bck_dir

# Add configuration to skel for new users
bck_dir=$(pwd)
cd /etc/skel
git init
git remote add origin https://github.com/galaunay/config
git remote update
git clean -f
git checkout master
git submodule update --init --recursive
# Add dummy .authinfo file and Downloads folder (for qute)
touch .authinfo.gpg
mkdir Downloads
cd $bck_dir

# semacs
HOME=/home/liveuser; emacs --eval '(kill-emacs)'
HOME=/home/liveuser; emacs --eval '(kill-emacs)'

# SSHD
sed -i 's/#\(PermitRootLogin \).\+/\1no/' /etc/ssh/sshd_config
sed -i 's/#\(PasswordAuthentication \).\+/\1no/' /etc/ssh/sshd_config

# Pacman
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist
pacman-key --init
pacman-key --populate archlinux
pacman -Suy --noconfirm

# clamav
useradd -u 64 clamav

# Journal
sed -i 's/#\(Storage=\)auto/\1volatile/' /etc/systemd/journald.conf

# Shutdown keys
sed -i 's/#\(HandleSuspendKey=\)suspend/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleHibernateKey=\)hibernate/\1ignore/' /etc/systemd/logind.conf
sed -i 's/#\(HandleLidSwitch=\)suspend/\1ignore/' /etc/systemd/logind.conf

# Add library paths
mkdir -p /etc/ld.so.d
touch /etc/ld.so.d/libc.conf
cat >> /etc/ld.so.d/libc.conf <<EOL
/usr/local/lib
/usr/local/lib64
EOL
ldconfig

# Remove vbox things
rm -f /usr/lib/modules-load.d/virtualbox-guest-dkms.conf
useradd kvm
useradd render
useradd vboxuser

# Services
systemctl enable pacman-init.service choose-mirror.service
systemctl set-default multi-user.target
systemctl disable getty@.service
systemctl disable getty@tty1.service
systemctl enable autologin@liveuser.service
systemctl enable NetworkManager.service
systemctl enable nullmailer.service

# time synchronization
# timedatectl set-ntp  yes
