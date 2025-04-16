# Use the official Python image as a base
FROM python:3.9-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    firefox-esr \
    wget \
    unzip \
    xvfb \
    cron \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* 

# 2. Install specific Chrome version (stable)
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/googlechrome-linux-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# 3. Install ChromeDriver from Chrome for Testing
RUN CHROME_VERSION="135.0.7049.84" \
    && wget -O /tmp/chromedriver.zip \
    "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chromedriver-linux64.zip" \
    && unzip /tmp/chromedriver.zip -d /usr/local/bin/ \
    && mv /usr/local/bin/chromedriver-linux64/chromedriver /usr/local/bin/ \
    && rm -rf /tmp/chromedriver.zip /usr/local/bin/chromedriver-linux64 \
    && chmod +x /usr/local/bin/chromedriver

# Verify installations
RUN google-chrome --version && chromedriver --version

# Set display port for Xvfb
ENV DISPLAY=:99

# Set up chromedriver PATH 
ENV PATH="/usr/local/bin:${PATH}"

# Create and set working directory
WORKDIR /app

# Copy requirements file first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY getprices.py graph.py products.json price.json dc /app

# Copy your cron configuration
COPY crontab /etc/cron.d/scraper-cron

# Give execution rights
RUN chmod 0644 /etc/cron.d/scraper-cron

# Ensure proper permissions
RUN chmod 777 /tmp && \
    # chmod +x /usr/local/bin/geckodriver && \
    mkdir -p /app/data

# Apply cron job
RUN crontab /etc/cron.d/scraper-cron

# Create the log file
RUN touch /var/log/cron.log

# Run cron in foreground
CMD ["cron", "-f"]

# Command to run your scripts (modify as needed)
# You might want to use an entrypoint script instead
# CMD ["python", "getprices.py"]
