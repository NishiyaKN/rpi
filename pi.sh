#!/bin/bash
# 68.7M RAM usage on idle
# 1.4G disk usage
### SSH with kitty ###
kitty +kitten ssh user@hostname.local

### CONFIGURE RASPBERRY PI ZERO 2 W ###

sudo apt update && sudo apt upgrade -y
sudo apt install -y git pip tmux chromium-chromedriver chromium-browser # on raw Debian its chromium and chromium-driver
pip3 install beautifulsoup4 lxml pandas selenium requests

### Optional packages ###
sudo apt install vim kitty

### DOTFILES ###
git clone https://github.com/KenichiNishiya/rpi.git
cd rpi
cp vimrc ../.vimrc
cp bash_aliases ../.bash_aliases
cp tmux.conf ../.tmux.conf
tmux
tmux source .tmux.conf

# Commit on github without the need to type the credentials
git config --global credential.helper store
git config --global user.email "email"
git config --global user.name "name"

###########################################################
### CONFIGURE ZRAM ###
git clone https://github.com/foundObjects/zram-swap
cd zram-swap
sudo ./install.sh
cd ..
sudo mv zram-swap /opt

# Test if it's working
zramctl

# See which compression algorithm it's using
cat /sys/block/zram0/comp_algorithm

# Change compression algorithm
sudo vi /etc/default/zram-swap
# Change to zstd for better compression ratio or lzo for best compression speed
_zram_algorithm="lzo"

###########################################################
### Lowering power consumption ###
'https://www.cnx-software.com/2021/12/09/raspberry-pi-zero-2-w-power-consumption/'

sudo vi /boot/config.txt

# Disable audio L53
dtparam=audio=off

# Disable camera L56
camera_auto_detect=0
 
# Disable display L59
display_auto_detect=0

# Leave more RAM to CPU intead of GPU, put anywhere:
gpu_mem=16

# Disable HDMI
sudo raspi-config
'Advanced options -> GL driver'
# Install whatever packages are needed, then select the following option:
'G1 Legacy'


sudo vi /etc/rc.local
# Add the following line before exit 0:
/usr/bin/tvservice -o

###########################################################
### Installing pihole ###
'https://www.crosstalksolutions.com/the-worlds-greatest-pi-hole-and-unbound-tutorial-2023/'

# Set static IP for the rpi

curl -sSL https://install.pi-hole.net | sudo bash
# Go throught the installation process

# Change the admin webpage password:
pihole -a -p

# Go to the admin webpage on your browser
http://[static IP]/admin

# Add more domains to adlist
https://firebog.net/
# Then go to Tools > Update Gravity in order to update the list

# Rate limited
sudo vi /etc/pihole/pihole-FTL.conf
# Paste the following line to disable rate limit
RATE_LIMIT=0/0

# Set unbound
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
sudo service unbound status # Should say active (running)
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

### Unbound optimization ### 
'https://www.reddit.com/r/pihole/comments/d9j1z6/unbound_as_recursive_dns_server_slow_performance/'

sudo vi /etc/dnsmasq.d/01-pihole.conf
# Disable cache, since unbound already takes care of it
cache-size=0

sudo vi /etc/unbound/unbound.conf.d/pi-hole.conf
# Paste the following to the end of the file

cache-min-ttl: 0
serve-expired: yes
# the rrset-cache needs to be double the msg-cache. 8/16m for both would probably be enough
msg-cache-size: 32m
rrset-cache-size: 64m

sudo service unbound restart
sudo service unbound status

### Pihole log file ###
'https://www.reddit.com/r/pihole/comments/sjl444/piholelog_is_10gb/'

vim /var/log/pihole.log

###########################################################
### Python scripts ###

cd 
git clone https://github.com/KenichiNishiya/pyrice-logger.git

# Change the username on those config files
vi $HOME/rpi/auto/ba/ba-banner.service
vi $HOME/pyrice-logger/asus/asus.service
sudo cp $HOME/rpi/auto/ba/ba-banner.* /etc/systemd/system
sudo cp $HOME/pyrice-logger/asus/asus.* /etc/systemd/system
sudo systemctl enable --now ba-banner.timer
sudo systemctl enable --now asus.timer

# https://patrikmojzis.medium.com/how-to-run-selenium-using-python-on-raspberry-pi-d3fe058f011
# https://stackoverflow.com/questions/32173839/easyprocess-easyprocesscheckinstallederror-cmd-xvfb-help-oserror-errno

# sudo apt install xvfb
# pip install xvfbwrapper pyvirtualdisplay

# '
# from pyvirtualdisplay import Display
# display = Display(visible=0, size=(800, 600))
# display.start()
# '

sudo apt install python3-numpy python3-selenium python3-plotly python3-pandas python3-bs4

### GECKODRIVER ###
# Download the ARM64 compatible binary
wget https://github.com/mozilla/geckodriver/releases/download/v0.34.0/geckodriver-v0.34.0-linux-aarch64.tar.gz

# Extract and install
tar -xvzf geckodriver-v0.34.0-linux-aarch64.tar.gz
sudo mv geckodriver /usr/local/bin/
sudo chmod +x /usr/local/bin/geckodriver

sudo apt update
sudo apt install firefox-esr -y


###########################################################
### ttyd (web based terminal) ###

sudo apt-get update
sudo apt-get install -y build-essential cmake git libjson-c-dev libwebsockets-dev
git clone https://github.com/tsl0922/ttyd.git
cd ttyd && mkdir build && cd build
cmake ..
make && sudo make install

ttyd --credential user:passwd --writable --port 3000 --cwd /home/zero bash

sudo cp ~/rpi/auto/ttyd.service /etc/systemd/system/ttyd.service
sudo systemctl enable --now ttyd.service

###########################################################
### DOCKER ###
# https://blog.rosnertech.com.br/arquivos/756

sudo apt install apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io -y

sudo systemctl start docker
sudo systemctl enable docker

sudo usermod -aG docker $USER
newgrp docker

docker --version

### DOCKER COMPOSE ###

sudo curl -l "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
