import requests
import json
from pathlib import Path
import argparse

AUTH_FILE = Path('dc')

def notify_discord(component, new_price, old_price=None, url=None):
    """Send price alerts to Discord"""
    if not AUTH_FILE.exists():
        print("⚠️ Discord auth file not found")
        return
        
    try:
        with open(AUTH_FILE) as f:
            token = f.read().strip()
        
        # Convert prices to floats first
        new_price_float = float(new_price)
        
        if old_price:
            old_price_float = float(old_price)
            change = new_price_float - old_price_float
            message = (
                f"🔻 Price drop for {component}\n"
                f"Was: R$ {old_price_float:.2f}\n"
                f"Now: R$ {new_price_float:.2f}\n"
                f"Saved: R$ {abs(change):.2f} ({abs(change)/old_price_float*100:.1f}%)\n"
                f"{url if url else ''}"
            )
        else:
            message = f"📊 New tracking for {component}: R$ {new_price_float:.2f}\n{url if url else ''}"
            
        response = requests.post(
            "https://discord.com/api/v9/channels/1180832500403155095/messages",
            json={"content": message},
            headers={"Authorization": f"Bot {token}", "Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
    except Exception as e:
        print(f"⚠️ Discord notification failed: {str(e)}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--component', required=True)
    parser.add_argument('--new-price', required=True)
    parser.add_argument('--old-price', required=False)
    parser.add_argument('--url', required=False)
    args = parser.parse_args()
    
    notify_discord(
        component=args.component,
        new_price=args.new_price,
        old_price=args.old_price,
        url=args.url
    )

if __name__ == "__main__":
    main()
