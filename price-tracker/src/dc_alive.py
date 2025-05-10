import requests
import json
from pathlib import Path
from datetime import datetime  # <-- Add this import

AUTH_FILE = Path('dc')

def notify_discord():
    if not AUTH_FILE.exists():
        print("⚠️ Discord auth file not found")
        return
        
    try:
        with open(AUTH_FILE) as f:
            token = f.read().strip()
            current_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")  # Format: "2023-12-31 23:59:59"
            message = f"YZK is operational (Time: {current_time})"  # <-- Add timestamp to message
            
        response = requests.post(
            "https://discord.com/api/v9/channels/1067805361911910461/messages",
            json={"content": message},
            headers={"Authorization": f"Bot {token}", "Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
    except Exception as e:
        print(f"⚠️ Discord notification failed: {str(e)}")

def main():
    notify_discord()

if __name__ == "__main__":
    main()
