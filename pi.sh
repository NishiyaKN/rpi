###########################################################
### RASPBERRY PI ZERO 2 W - PRE-CONFIGURATION ###

### No connection ###
# Radio may be soft blocked
rfkill list

sudo rfkill unblock wifi
sudo nmcli radio wifi on

# Interface may be down
ip link show wlan0

sudo ip link set wlan0 up

# Try to connect
sudo nmcli dev wifi connect "YOUR_WIFI_NAME" password "YOUR_PASSWORD"

### No SSH ###
sudo systemctl enable --now ssh

### SSH host identification has changed ###
# Just remove the old SSH fingerprint
ssh-keygen -R [IP-ADDRESS]

###########################################################
### RASPBERRY PI ZERO 2 W - SYSTEM CONFIGURATION ###
sudo apt update && sudo apt upgrade -y
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt install -y git pip tmux sysstat vim dnsutils chrony fail2ban speedtest minidlna iotop

pip3 install beautifulsoup4 lxml pandas requests

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

### Fail2Ban
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
### CROND ###
sudo crontab -e
* * * * * /home/zero/rpi/scripts/speedtest-log.sh

crontab -e
* * * * * /home/zero/rpi/scripts/baka.sh

###########################################################
### CONFIGURE ZRAM ###
sudo apt install systemd-zram-generator

# Change or create the systemd config for zram
sudo vim /etc/systemd/zram-generator.conf

# Add this
'
[zram0]
zram-size = min(ram * 3 / 4, 4096)
compression-algorithm = zstd
swap-priority = 100
'

sudo systemctl daemon-reload
sudo reboot

# Confirm it's working
zramctl
swapon --show

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
### SWAP FILE ###
# 2GB is enough for the Zero 2
cd /mnt/ssd
sudo dd if=/dev/zero of=swapfile bs=1M count=2048
sudo chmod 600 swapfile
sudo mkswap swapfile
sudo swapon swapfile

# Add to fstab
sudo vim /etc/fstab
'
/mnt/ssd/swapfile  none  swap  sw  0  0
'

# Test if fstab is ok and will not die
sudo findmnt --verify

# Apply with
sudo systemctl daemon-reload

# Validated with
swapon --show

###########################################################
### DISABLE LOCAL SWAPFILE ###
# Helps to save SD card life
# May or may not exist in your system by default
sudo swapoff /var/swap
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile

###########################################################
### SWAP PARTITION ###
# Not recommended, unless running on HDD, otherwise prefer swapfile
sudo swapoff -a

sudo umount /dev/sdXY
# If the partition is not already a swap partition
sudo mkswap /dev/sdXY

sudo swapon /dev/sdXY
swapon --show

# To make it permanent
echo '/dev/sdXY none swap sw,pri=10 0 0' | sudo tee -a /etc/fstab

###########################################################
### Adjust swappiness ###
sysctl vm.swappiness
sudo vim /etc/sysctl.d/99-swappiness.conf
'
vm.swappiness=25
'
sudo sysctl --system

###########################################################
### Lowering power consumption ###
'https://www.cnx-software.com/2021/12/09/raspberry-pi-zero-2-w-power-consumption/'

sudo vim /boot/firmware/config.txt

# Disable audio L53
dtparam=audio=off

# Disable camera L56
camera_auto_detect=0
 
# Disable display L59
display_auto_detect=0

# Leave more RAM to CPU intead of GPU, put it in the end of the file:
gpu_mem=16

# Disable graphics drivers (comment out both)
dtoverlay=vc4-kms-v3d
max_framebuffers=2

# Disable HDMI
sudo raspi-config
'Advanced options -> GL driver'
# Install whatever packages are needed, then select the following option:
'G1 Legacy'

sudo vi /etc/rc.local
# Add the following line before exit 0:
/usr/bin/tvservice -o

###########################################################
### JOURNALCTL LOGGING OVER BOOTS ###
# NOT YET WORKING
sudo mkdir -p /var/log/journal
sudo vim /etc/systemd/journald.conf

# Change these settings:
'
Storage=persistent
SystemMaxFiles=10
'
sudo systemctl restart systemd-journald

###########################################################
### ENABLE WATCHDOG ###
# It reboots the pi if the system ever hangs for some reason

sudo apt update && sudo apt install watchdog -y

sudo vim /boot/firmware/config.txt
# Paste somewhere in the file:
'
dtparam=watchdog=on
'

sudo vim /etc/systemd/system.conf
# Uncomment and set to 14s (cannot be over 14s)
'
RuntimeWatchdogSec=14s
'

sudo vim /etc/watchdog.conf
# Uncomment and set
'
watchdog-device = /dev/watchdog
watchdog-timeout = 15
max-load-1 = 24
'

sudo systemctl enable --now watchdog

###########################################################
### DISABLE WIFI POWER MANAGEMENT MODE ###
# If the pi suddenly becomes unaccessible on the network, this may be the culprit, check with
iwconfig

# Disable permanently 
sudo vim /etc/rc.local
'
#!/bin/sh -e
# --- DISABLE WIFI POWER MANAGEMENT ---
/sbin/iw dev wlan0 set power_save off
# -------------------------------------
exit 0
'
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

sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER
newgrp docker

docker --version

###########################################################
### DOCKER STATS NOT SHOWING RAM USAGE ###
# This is done in the rpi to save some performance
sudo vim /boot/firmware/cmdline.txt
# Append to the end of the line
cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1

sudo reboot

###########################################################
### DOCKER SERVICES ###

### HOMER ### 
# Configure the correct IP addresses on assets/config.yml

### PI HOLE ###
# .env with 'PIHOLE_PASS'
# Add more domains to adlist: https://firebog.net/
# Set custom DNS server 'unbound%5335' on System > DNS > Custom DNS servers (disable any other DNS provider)

### WIREGUARD ###
# .env with 'DDNS', 'PASSWD', 'SERVER_IP', 'DUCKDNS_TOKEN' and 'DNS_SUBDOMAIN'
# PASSWD needs the hashed password, get it with:
# Need to open port 51820 UDP
docker run --rm -it ghcr.io/wg-easy/wg-easy wgpw 'YOUR_PASSWORD'

### TRANSMISSION ###
# .evn with TR_USER and TR_PASS
# If torrenting from directories different than docker's, refer to the 'ADD DRIVES' section

### FILEBROWSER ###
# First run it will print a password for the user 'admin', so watch the logs
# Change the user and passwd in Settings > User Management
# Password needs to be 12+ characters

###########################################################
### PI SERVICES ###

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
force user = zero
'
# The last line prevents permission conflicts with Docker/Transmission

# Create a SMB passwd (replace the user if needed)
sudo smbpasswd -a zero

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

###########################################################
### PI TAKING TOO LONG TO BOOT ###

# Look what process are taking too much time
systemctl-analyze blame

# Tree style visualization, red ones are the problematic (possibly)
systemctl-analyze critical-chain

# openmediavault-issue.service > not useful for headless environment
sudo systemctl disable openmediavault-issue.service
sudo systemctl mask openmediavault-issue.service

# e2scrub_reap > only used for LVM snapshots
sudo systemctl disable e2scrub_reap.service

# SSH may be wating for DNS, but Pi-hole is the one who serves DNS, disable this: 
echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config

# Samba searches for AD
sudo systemctl disable --now samba-ad-dc.service

# Docker may ignore the 90s timeout to reboot, change it to kill it in less time
sudo vim /etc/systemd/system.conf
sudo vim /etc/systemd/user.conf
'
DefaultTimeoutStopSec=20s
'

###########################################################
### AUTO WIREGUARD ON/OFF ON ANDROID - WIREGUARD CONFIGURATION###

# On Tasker
# Create Profile > State > Net > Wifi Connected > SSID: [] > Active: Any
# New Task > VPN OFF > Tasker > Tasker Function > WireGuardSetTunnel > Tunnel Up: No > Tunnel Name: []
# Long press the "VPN OFF" on the profile > Exit Task > VPN ON > Tasker Function > WireGuardSetTunnel > Tunnel Up: Yes > Tunnel Name: []

# On WireGuard
# Settings > Advanced > Allow remote control apps
# Click on the VPN tunnel > Edit > Exclude application > Select Tasker > Save

###########################################################
### Installing pihole ###
'https://www.crosstalksolutions.com/the-worlds-greatest-pi-hole-and-unbound-tutorial-2023/'

# Set static IP for the rpi

curl -sSL https://install.pi-hole.net | sudo bash
# Go throught the installation process

# Change the admin webpage password:
sudo pihole setpassord [passwd]

# Go to the admin webpage on your browser
http://[static IP]/admin

# Add more domains to adlist
https://firebog.net/
# Then go to Tools > Update Gravity in order to update the list

### Rate limited ###
sudo vi /etc/pihole/pihole-FTL.conf
# Paste the following line to disable rate limit
RATE_LIMIT=0/0

### Set unbound ###
sudo apt install unbound -y
sudo vi /etc/unbound/unbound.conf.d/pi-hole.conf
# Paste the following:
'
server:
# If no logfile is specified, syslog is used
# logfile: "/var/log/unbound/unbound.log"
verbosity: 0

interface: 127.0.0.1
port: 5335
do-ip4: yes
do-udp: yes
do-tcp: yes

# May be set to yes if you have IPv6 connectivity
do-ip6: no

# You want to leave this to no unless you have *native* IPv6. With 6to4 and
# Terredo tunnels your web browser should favor IPv4 for the same reasons
prefer-ip6: no

# Use this only when you downloaded the list of primary root servers!
# If you use the default dns-root-data package, unbound will find it automatically
#root-hints: "/var/lib/unbound/root.hints"

# Trust glue only if it is within the servers authority
harden-glue: yes

# Require DNSSEC data for trust-anchored zones, if such data is absent, the zone becomes BOGUS
harden-dnssec-stripped: yes

# Dont use Capitalization randomization as it known to cause DNSSEC issues sometimes
# see https://discourse.pi-hole.net/t/unbound-stubby-or-dnscrypt-proxy/9378 for further details
use-caps-for-id: no

# Reduce EDNS reassembly buffer size.
# IP fragmentation is unreliable on the Internet today, and can cause
# transmission failures when large DNS messages are sent via UDP. Even
# when fragmentation does work, it may not be secure; it is theoretically
# possible to spoof parts of a fragmented DNS message, without easy
# detection at the receiving end. Recently, there was an excellent study
# >>> Defragmenting DNS - Determining the optimal maximum UDP response size for DNS <<<
# by Axel Koolhaas, and Tjeerd Slokker (https://indico.dns-oarc.net/event/36/contributions/776/)
# in collaboration with NLnet Labs explored DNS using real world data from the
# the RIPE Atlas probes and the researchers suggested different values for
# IPv4 and IPv6 and in different scenarios. They advise that servers should
# be configured to limit DNS messages sent over UDP to a size that will not
# trigger fragmentation on typical network links. DNS servers can switch
# from UDP to TCP when a DNS response is too big to fit in this limited
# buffer size. This value has also been suggested in DNS Flag Day 2020.
edns-buffer-size: 1232

# Perform prefetching of close to expired message cache entries
# This only applies to domains that have been frequently queried
prefetch: yes

# One thread should be sufficient, can be increased on beefy machines. In reality for most users running on small networks or on a single machine, it should be unnecessary to seek performance enhancement by increasing num-threads above 1.
num-threads: 1

# Ensure kernel buffer is large enough to not lose messages in traffic spikes
so-rcvbuf: 1m

# Ensure privacy of local IP ranges
private-address: 192.168.0.0/16
private-address: 169.254.0.0/16
private-address: 172.16.0.0/12
private-address: 10.0.0.0/8
private-address: fd00::/8
private-address: fe80::/10
'

sudo service unbound restart
sudo service unbound status 
# Should say active (running)

# Test with
dig google.com @127.0.0.1 -p 5335
# On the 4th line, next to status it should be NOERROR
    # If it says SERVFAIL then:
    sudo vi /etc/resolvconf.conf
    # Comment the last line, which should be
    # unbound_conf=/etc/unbound/unbound.conf.d/resolvconf_resolvers.conf
    sudo rm /etc/unbound/unbound.conf.d/resolvconf_resolvers.conf
    sudo service unbound restart
    # Test again
    dig google.com @127.0.0.1 -p 5335

# Go to the admin webpage
'Side bar -> Settings -> DNS ->[clear upstream dns servers -> add Custom 1(IPv4) as [127.0.0.1#5335] -> save'

# If using docker:
'Side bar -> Settings -> DNS ->[clear upstream dns servers -> add Custom 1(IPv4) as [unbound#5335] -> save'

### Unbound optimization ### 
'https://www.reddit.com/r/pihole/comments/d9j1z6/unbound_as_recursive_dns_server_slow_performance/'

sudo vi /etc/dnsmasq.d/01-pihole.conf
# Disable cache, since unbound already takes care of it
cache-size=0

sudo vi /etc/unbound/unbound.conf.d/pi-hole.conf
# Paste the following to the end of the file
'
cache-min-ttl: 0
serve-expired: yes
# the rrset-cache needs to be double the msg-cache. 8/16m for both would probably be enough
msg-cache-size: 8m
rrset-cache-size: 16m
'

sudo service unbound restart
sudo service unbound status

### Pihole log file ###
'https://www.reddit.com/r/pihole/comments/sjl444/piholelog_is_10gb/'

vim /var/log/pihole.log

###########################################################
### OpenMediaVault ###
# https://pimylifeup.com/raspberry-pi-openmediavault/
sudo apt update
sudo apt upgrade

wget -O - https://raw.githubusercontent.com/OpenMediaVault-Plugin-Developers/installScript/master/preinstall | sudo bash
sudo reboot

wget -O - https://raw.githubusercontent.com/OpenMediaVault-Plugin-Developers/installScript/master/install | sudo bash
sudo reboot

# network-manager will be removed, you need to connect to a HDMI monitor and run this command:
sudo omv-firstaid
# Configure the network
sudo reboot

# Default login:
'
admin
openmediavault
'

# Check which port it's running
sudo grep listen /etc/nginx/sites-enabled/openmediavault-webgui
# If using with pihole, I recommend using the port 81 for omv

# If using samba for file sharing
sudo systemctl enable --now smbd
# Note that omv will disable sbmd everytime a new shared folder is added

# Set proper file permission (full access to everyone)
sudo chmod -R 777 /path/to/shared_folder
sudo chown -R nobody:nogroup /path/to/shared_folder

# Enable sharing of the root / main disk
# Install the plugin:
'sharerootfs'


###########################################################
### PiVPN ###
curl -L https://install.pivpn.io | bash 
# Select WireGuard instead of OpenVPN
# Select 'DNS Entry' instead of 'Public IP' if your ISP uses CGNAT
# Create a free DDNS domain on duckdns.org and enter the newly created domain in the DNS Entry

# Add a client profile to connect to the vpn
pivpn add
pivpn -qr
# Install WireGuard to scan the QR code

### Set up Port Forwarding ###
# Default port is 51820
# Protocol: UDP
# Local IP: homeserver's IP

###########################################################
### Torrenting with Transmission ###
# WebUI on port :9091

sudo apt install transmission-daemon
sudo systemctl stop transmission-daemon
# Edit settings (must stop service first!)
sudo vim /etc/transmission-daemon/settings.json
# Change "rpc-whitelist-enabled": false, to allow access of the WebUI from your PC
# Change "rpc-username" and "rpc-password"
sudo systemctl start transmission-daemon

### Relocating torrents ###

# From the PC with the torrent file, run:
rsync -av --progress /path/to/My_Linux_ISO/ zero@<PI_IP_ADDRESS>:/home/zero/tohent/

# Change permissions so transmission can access the files
sudo chown -R debian-transmission:debian-transmission /home/zero/tohent/
sudo chmod -R 775 /home/zero/tohent/
