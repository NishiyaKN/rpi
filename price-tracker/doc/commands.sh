# Docker basic commands
docker stop yzk && docker rm yzk
docker volume rm app_data
docker build -t price-tracker .
docker run -d --restart unless-stopped --name yzk -v app_data:/app price-tracker
docker exec -ti yzk bash

# Check docker volume
docker volume ls
docker volume inspect app_data

# Usually only root has permission to even see what is happening in the volume, to change this:
# cd /var/lib 
# sudo chmod -R 771 docker # full access for owner and group
# sudo chmod g+s docker # future files inherit group
# sudo chgrp -R docker docker # change group ownership

# Now fix the permissions for dir and files (may take a while)
# sudo find docker -type f -exec chmod 660 {} +
# sudo find docker -type d -exec chmod 771 {} +

# Test the discord notification 
python discord_notifier.py --component "Test Product" --new-price "8999.99" --old-price "9999.99" --url "https://example.com/product"

- The cronjob is set to send Hello Its me every 1 hour to the cron.log
- 13:20 the container was run
- Maybe we could add a code that sends a discord message everytime the docker is running so we know that it is alive
- Maybe we could continuouly send the cron.log file to the mounted volume if the container exits we know what was the last cron logs
- Maybe we could set to automatically restart the container if it exits
