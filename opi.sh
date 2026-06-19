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

##########################################################
### WIREGUARD WITH WEB UI ###
# Change for the lateste version
wget https://github.com/ngoduykhanh/wireguard-ui/releases/download/v0.6.2/wireguard-ui-v0.6.2-linux-arm64.tar.gz

tar -xvf wireguard-ui-*-linux-arm64.tar.gz
sudo mv wireguard-ui /usr/local/bin/
sudo chmod +x /usr/local/bin/wireguard-ui
rm wireguard-ui-*-linux-arm64.tar.gz

sudo vim /etc/wireguard/db/users/admin.json
'
{
  "username": "<username>",
  "password": "<password>",
  "password_hash": "",
  "admin": true
}
'

sudo vim /etc/systemd/system/wireguard-ui.service
'
[Unit]
Description=WireGuard UI
After=network.target

[Service]
Type=simple
# "0.0.0.0" allows access from your LAN. Change to "127.0.0.1" if using Nginx proxy.
EnvironmentFile=-/etc/wireguard-ui/env
ExecStart=/usr/local/bin/wireguard-ui --bind-address 0.0.0.0:5000 --session-secret REPLACE_WITH_RANDOM
WorkingDirectory=/etc/wireguard
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
'

SECRET=$(openssl rand -hex 32)
sudo sed -i "s|REPLACE_WITH_RANDOM|$SECRET|" /etc/systemd/system/wireguard-ui.service
sudo systemctl daemon-reload
sudo systemctl enable --now wireguard-ui

mkdir -p /etc/wireguard-ui
cat > /etc/wireguard-ui/env <<EOF
WGUI_USERNAME=changehere
WGUI_PASSWORD=changehere
WGUI_SESSION_SECRET=$(openssl rand -hex 32)
EOF
chmod 600 /etc/wireguard-ui/env

# Access it on your.ip.addr:5000 and configure this on 'Wireguard Server'
# Post Up Script
iptables -I FORWARD 1 -i wg0 -j ACCEPT; iptables -I FORWARD 1 -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
# Post Down Script
iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o wlan0 -j MASQUERADE

# Initiate
sudo wg-quick up wg0

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

###########################################################
### Installing pihole ###
'https://www.crosstalksolutions.com/the-worlds-greatest-pi-hole-and-unbound-tutorial-2023/'

sudo systemctl disable --now dnsmasq

curl -sSL https://install.pi-hole.net | sudo bash
# Go throught the installation process

# Change the admin webpage password:
sudo pihole setpassword [passwd]

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
