# Use official Python slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev cron vim less && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy app files
COPY src/*.py /app/
COPY config/*.json /app/
COPY dc /app/dc 

RUN chmod 0666 /app/*.json /app/dc

# Set up cron job
COPY ./docker/cronjob /etc/cron.d/price-tracker
RUN chmod 0644 /etc/cron.d/price-tracker

# Apply cron job and start cron in foreground
RUN crontab /etc/cron.d/price-tracker
CMD ["cron", "-f"]
