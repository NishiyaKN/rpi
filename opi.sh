sudo nmcli radio wifi on
sudo nmcli dev wifi connect "YOUR_WIFI_NAME" password "YOUR_PASSWORD"
sudo systemctl enable --now ssh

###########################################################
### OPI 4 Pro - SYSTEM CONFIGURATION ###

# Protect kernel from being replaced
sudo apt-mark hold linux-image-current-sun60iw2 linux-dtb-current-sun60iw2 linux-u-boot-orangepi4pro-current orangepi-firmware
sudo apt-mark showhold

# Installs
sudo apt update && sudo apt upgrade -y
sudo apt install -y git pip tmux sysstat vim dnsutils chrony fail2ban minidlna iotop iftop wireguard

pip3 install beautifulsoup4 lxml pandas requests

##########################################################
### CHANGE DEFAULT ACCOUNT NAME ###

# as root, ensure root has a password and can SSH in
passwd root
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart ssh

# New terminal to the rest
ssh root@192.168.68.4

# make sure no orangepi processes remain
loginctl terminate-user orangepi 2>/dev/null
pkill -u orangepi; sleep 2; pkill -9 -u orangepi 2>/dev/null

usermod -l opi -d /home/opi -m orangepi
groupmod -n opi orangepi
grep -rl orangepi /etc/sudoers.d/ /etc/ssh/sshd_config.d/ 2>/dev/null

# Check if sudo is ok
su - opi
sudo true # Should return nothign

# Now before closing the root ssh connection, try with the new user
ssh opi@192.168.68.4

##########################################################
### DOTFILES ###
git clone https://github.com/NishiyaKN/rpi.git
cd rpi
cp -r docker ../
cp config/.vimrc ../.vimrc
cp config/.bash_aliases ../.bash_aliases

# Commit on github without the need to type the credentials
git config --global credential.helper store
git config --global user.email "email"
git config --global user.name "name"

##########################################################
### Fail2Ban ###
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo vim /etc/fail2ban/jail.local
# Change sshd section to this
'
[sshd]
enabled = true
port    = ssh
filter  = sshd
backend = systemd
maxretry = 5
bantime = 1h
'
# Find this line, uncomment and add
'
ignoreip = 127.0.0.1/8 ::1 192.168.0.0/16
'

sudo systemctl enable --now fail2ban

# You can see how many bots have been stopped with this
sudo fail2ban-client status sshd

##########################################################
### MiniDLNA ###
sudo vim /etc/minidlna.conf
'
media_dir=V,/mnt/ssd/anime

friendly_name=iroha

inotify=yes
'
sudo systemctl enable --now minidlna

# Manually for media
sudo minidlnad -R

### CHRONY ###
sudo systemctl enable chrony

# Test if it's working
chronyc tracking

###########################################################
### ADD DRIVES ###
lsblk -f
# Copy the UUID of the drive

sudo mkdir -p /mnt/ssd
sudo chown -R 1000:1000 /mnt/ssd

sudo vim /etc/fstab
# Add in the end
'
UUID=YOUR-UUID-HERE  /mnt/ssd  ext4  defaults,noatime,nofail  0  2
'

sudo mount -a
sudo systemctl daemon-reload

# If using transmission:
mkdir -p /mnt/ssd/transmission/downloads/complete
mkdir -p /mnt/ssd/transmission/downloads/incomplete
mkdir -p /mnt/ssd/transmission/watch

sudo chown -R 1000:1000 /mnt/ssd/transmission

###########################################################
### DOCKER ###
# https://docs.docker.com/engine/install/debian/

# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker

###########################################################
### OPI SERVICES ###

### SAMBA ###
sudo apt install samba samba-common-bin -y

sudo vim /etc/samba/smb.conf
# Paste in the end
'
[ssd]
path = /mnt/ssd
writeable = yes
browseable = yes
create mask = 0777
directory mask = 0777
public = no
force user = opi
'
# The last line prevents permission conflicts with Docker/Transmission

# Create a SMB passwd (replace the user if needed)
sudo smbpasswd -a opi

# Optionally, create a guest share
'
[guest_share]
path = /mnt/ssd/guests
writeable = no
guest ok = yes
guest only = yes
read only = yes
force user = zero
'

sudo systemctl restart smbd

##########################################################
### TTYD ###
sudo apt install -y build-essential cmake git libjson-c-dev libwebsockets-dev
cd ~/.config
git clone https://github.com/tsl0922/ttyd.git
cd ttyd && mkdir build && cd build
cmake ..
make && sudo make install

# Test with this (change the user and passwd)
ttyd --credential user:passwd --writable --port 7681 --cwd /home/zero bash

# Auto start with a systemd service (CHANGE THE USER AND PASSWD!!!!!!!!!!!)
sudo vim /etc/systemd/system/ttyd.service
'
[Unit]
Description=ttyd initializer
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=10
User=root
Group=root
ExecStart=/usr/local/bin/ttyd --credential user:passwd --writable --port 7681 --cwd /home/zero bash

[Install]
WantedBy=multi-user.target
'
sudo systemctl enable --now ttyd.service


##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
##########################################################
