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



