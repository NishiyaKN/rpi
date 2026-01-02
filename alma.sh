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
