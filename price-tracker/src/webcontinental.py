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

PRICE_PATH = "price_history/webcontinental-prices.json"
PRODUCT_PATH = "products/webcontinental-products.json"

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
    
    # Remove all non-digit characters except commas and dots
    clean_str = re.sub(r'[^\d,.]', '', price_text)
    
    try:
        # US format detection (comma as thousand, dot as decimal)
        if '.' in clean_str and clean_str.find('.') > clean_str.find(','):
            return float(clean_str.replace(',', ''))
        
        # BR format detection (dot as thousand, comma as decimal)
        if ',' in clean_str:
            return float(clean_str.replace('.', '').replace(',', '.'))
        
        # Plain number without separators
        return float(clean_str)
        
    except ValueError:
        return 0.0

def load_json_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {} if 'prices' in filename else None

def scrape_product_price(scraper, url):
    """Simplified scraping function optimized for webcontinental"""
    try:
        # Realistic headers
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept-Language': 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7',
            'Referer': 'https://www.google.com/',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
        }
        
        response = scraper.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')

            # Remove popup close button if exists
            for close_button in soup.find_all(class_="close"):
                close_button.decompose() 

            # webcontinental price element
            price_elements = soup.find_all('span', class_='vtex-product-price-1-x-currencyInteger vtex-product-price-1-x-currencyInteger--boletopixtext')

            actual_price = price_elements[0].get_text(strip=True) + price_elements[1].get_text(strip=True) + '.00'
            if actual_price:
                return convert_brl_to_decimal(actual_price)
            
            # Check for unavailable products
            if soup.find(string=re.compile(r'(indispon[íi]vel|esgotado|unavailable)', re.I)):
                return 0.0
                
            return 0.0  # Price not found
            
        print(f"❌ HTTP Error {response.status_code}")
        return 0.0
        
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
            try:
                previous_price = price_history[product_name][-1]['price']
                if previous_price > current_price:
                    subprocess.run([
                        'python', 'discord_notifier.py',
                        '--component', product_name,
                        '--new-price', str(current_price),
                        '--old-price', str(previous_price),
                        '--url', url
                    ])
            except:
                print("No price has ever been recorded to the file")

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
