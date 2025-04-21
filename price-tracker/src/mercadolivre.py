import cloudscraper
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime
import time
import random
import subprocess

# Configuration
DELAY_BETWEEN_PRODUCTS = 45  # Base delay between products (seconds)
MIN_DELAY = 30               # Minimum delay (seconds)
MAX_DELAY = 60               # Maximum delay (seconds)
MAX_RETRIES = 3              # Max attempts per product
REQUEST_TIMEOUT = 60         # Request timeout (seconds)

PRICE_PATH = "price_history/mercadolivre-prices.json"
PRODUCT_PATH = "products/mercadolivre-products.json"

def create_custom_scraper():
    return cloudscraper.create_scraper(
        browser={
            'browser': 'chrome',
            'platform': 'windows',
            'desktop': True,
        },
        delay=random.uniform(7, 15),
    )

def convert_brl_to_decimal(price_text):
    if not price_text:
        return 0.0
    
    # Remove all commas and dots, append .00 to the price
    clean_str = float(re.sub(r'[,.]', '', price_text)+'.00')
    return clean_str

def load_json_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {} if 'prices' in filename else None

def scrape_product_price(scraper, url):
    try:
        response = scraper.get(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36...'
        })
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Find ALL price elements
            price_elements = soup.find_all('span', class_='andes-money-amount__fraction')
            
            if len(price_elements) >= 2:
                # Get the SECOND occurrence (actual price)
                actual_price = price_elements[1].get_text(strip=True)
                return convert_brl_to_decimal(actual_price)
            
            elif price_elements:
                # Fallback to first if only one exists
                return convert_brl_to_decimal(price_elements[0].get_text(strip=True))
            
            return 0.0  # No price found
            
    except Exception as e:
        print(f"⚠️ Scraping error: {str(e)}")
        return 0.0

def update_price_history():
    products = load_json_file(PRODUCT_PATH)
    if not products:
        print("❌ No products found in " + PRODUCT_PATH)
        return
        
    price_history = load_json_file(PRICE_PATH)
    scraper = create_custom_scraper()
    current_date = datetime.now().strftime("%Y-%m-%d")
    updated = False
    
    print(f"\n🛒 Starting Price Check at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    for product_name, url in products.items():
        print(f"\n🔍 Checking: {product_name}")
        print(f"🌐 URL: {url}")
        
        # Random delay with jitter
        delay = random.uniform(MIN_DELAY, MAX_DELAY)
        print(f"⏳ Waiting {delay:.1f} seconds...")
        time.sleep(delay)
        
        current_price = scrape_product_price(scraper, url)
        
        if current_price == 0.0:
            print(f"⏭️ Product unavailable or could not be scraped")
            continue
            
        print(f"💰 Current price: R$ {current_price:.2f}")
        
        # Initialize product history if not exists
        if product_name not in price_history:
            price_history[product_name] = []
            
        # Check for existing entry today
        today_entry = next((entry for entry in price_history[product_name] 
                          if entry['date'] == current_date), None)
        
        if today_entry:
            if today_entry['price'] < current_price:
                print(f"📈 Price changed from R$ {today_entry['price']:.2f}")
                # Call discord notifier
                subprocess.run([
                    'python', 'discord_notifier.py',
                    '--component', product_name,
                    '--new-price', str(current_price),
                    '--old-price', str(today_entry['price']),
                    '--url', url
                ])
                today_entry['price'] = current_price
                updated = True
            else:
                print("🔄 Price unchanged or higher")
        else:
            price_history[product_name].append({
                'date': current_date,
                'price': current_price
            })
            updated = True
    
    if updated:
        with open(PRICE_PATH, 'w', encoding='utf-8') as f:
            json.dump(price_history, f, indent=4, ensure_ascii=False)
        print("\n💾 Price history saved successfully")
    else:
        print("\n🤷 No price updates to save")

if __name__ == "__main__":
    update_price_history()
