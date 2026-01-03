####################################################
### ALMALINUX (OCI FREE TIER) CONFIGURATION ###
sudo dnf update -y
sudo dnf in epel-release -y
sudo dnf install wireguard-tools iptables-services d-y

### SWAPFILE (2GB) ###
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 swapfile
sudo mkswap swapfile
sudo swapon swapfile

# Add to fstab
sudo vim /etc/fstab
'
/swapfile  none  swap  sw  0  0
'

# Test if fstab is ok and will not die
sudo findmnt --verify

# Apply with
sudo systemctl daemon-reload

# Validated with
swapon --show

####################################################
### WIREGUARD ###
sudo vim /etc/wireguard/wg0.conf
sudo wg-quick up wg0

####################################################
### SERVER CHECK WITH TELEGRAM ###
# Message @BotFather on Telegram
# Send /newbot, give it a name, and a username
# Copy the API Token
# Message the bot, send anything (like "Hello")
# Get the Chat ID:
curl "https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates"

# Test if the credentials are working
TOKEN="<YOUR_BOT_TOKEN>"
CHAT_ID="<YOUR_CHAT_ID>"
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="Test message from OCI"

sudo cp ~/rpi/scripts/tg_server_check.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/tg_server_check.sh

# Add the script on crontab
'
* * * * * /usr/local/bin/tg_server_check.sh
'
####################################################
### FIREWALLD ###
sudo dnf in firewalld
sudo systemctl enable --now firewalld

####################################################
### DOCKER ###
sudo dnf remove -y podman podman-docker buildah skopeo
sudo dnf install -y dnf-plugins-core ca-certificates curl gnupg2

sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl enable --now docker
sudo usermod -aG docker $USER

### Error when enabling via systemd - xt_addrtype ###
# This happens due to the transition of iptables to nftables, force Docker to use the latter:
modprobe xt_addrtype

# If it works, then force it to load on boot
echo "xt_addrtype" | sudo tee /etc/modules-load.d/docker.conf
echo "br_netfilter" | sudo tee -a /etc/modules-load.d/docker.conf

# If loading the module don't work
sudo vim /etc/docker/daemon.json
'
{
  "iptables": "false"
}
'
