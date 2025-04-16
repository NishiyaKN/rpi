from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException, NoSuchElementException
from datetime import datetime
import json
import time
import os
from pathlib import Path
import gc

# Base directory (configurable via env var, defaults to /data)
BASE_DIR = Path(os.getenv("DATA_DIR", "/app"))

# File paths (all relative to BASE_DIR)
PRODUCTS_FILE = BASE_DIR / "products.json"
PRICES_FILE = BASE_DIR / "price.json"
AUTH_FILE = BASE_DIR / "dc"

# Create directory if needed
BASE_DIR.mkdir(parents=True, exist_ok=True)

# Initialize products data
try:
    with open(PRODUCTS_FILE) as f:
        products = json.load(f)['products']
    print(f"Loaded {len(products)} products from {PRODUCTS_FILE}")
except FileNotFoundError:
    print(f"Error: {PRODUCTS_FILE} not found")
    exit()

# Initialize price file if needed
if not PRICES_FILE.exists():
    with open(PRICES_FILE, 'w') as f:
        json.dump({p['name']: [] for p in products}, f, indent=2)
    print(f"Created new {PRICES_FILE}")

def get_browser():
    """Create a single optimized browser instance"""
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.set_preference("browser.cache.disk.enable", False)
    options.set_preference("browser.cache.memory.enable", False)
    options.set_preference("browser.cache.offline.enable", False)
    
    # Reduce memory usage
    options.set_preference("dom.ipc.processCount", 1)
    options.set_preference("dom.ipc.processCount.webIsolated", 1)
    
    return webdriver.Firefox(options=options)

def close_terabyte_popups(browser):
    """Handle Terabyte popups with minimal overhead"""
    try:
        # Try to close iframe popup if exists
        try:
            WebDriverWait(browser, 2).until(
                EC.frame_to_be_available_and_switch_to_it((By.CSS_SELECTOR, "iframe[src*='modal']"))
            )
            browser.find_element(By.CSS_SELECTOR, "button.tsG0HQh7bcmTha7pyanx-btn-close").click()
            browser.switch_to.default_content()
        except:
            pass
        
        # Try to close main popup if exists
        try:
            browser.find_element(By.CSS_SELECTOR, "span.fa-times").click()
        except:
            pass
    except:
        pass

def notify_discord(component, new_price, old_price=None):
    """Send price alerts to Discord with minimal memory usage"""
    if not AUTH_FILE.exists():
        return
        
    try:
        with open(AUTH_FILE) as f:
            token = f.read().strip()
        
        if old_price:
            change = float(new_price) - float(old_price)
            message = (
                f"🔻 Price drop for {component}\n"
                f"Was: R$ {old_price}\n"
                f"Now: R$ {new_price}\n"
                f"Saved: R$ {abs(change):.2f} ({abs(change)/float(old_price)*100:.1f}%)"
            )
        else:
            message = f"📊 New tracking for {component}: R$ {new_price}"
            
        requests.post(
            "https://discord.com/api/v9/channels/1180832500403155095/messages",
            json={"content": message},
            headers={"Authorization": f"Bot {token}", "Content-Type": "application/json"}
        )
    except Exception as e:
        print(f"Discord error: {str(e)}")

def parse_selector(selector_str):
    """Efficient selector parsing with minimal memory overhead"""
    if ':' not in selector_str:
        raise ValueError(f"Invalid selector format: {selector_str}")
    
    selector_type, value = selector_str.split(':', 1)
    return (getattr(By, selector_type.upper()), value)

def get_price_data():
    """Load price data efficiently"""
    try:
        with open(PRICES_FILE) as f:
            return json.load(f)
    except:
        return {p['name']: [] for p in products}

def save_price_data(data):
    """Save price data efficiently"""
    with open(PRICES_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def get_price(product, browser):
    """Check price for a single product with minimal memory usage"""
    print(f"\n🔍 Checking {product['name']}...")
    today = datetime.today().strftime('%Y-%m-%d')
    
    try:
        browser.get(product['url'])
        
        if 'popup_handler' in product:
            globals()[product['popup_handler']](browser)
        
        locator_type, locator_value = parse_selector(product['price_selector'])
        price_element = WebDriverWait(browser, 15).until(
            EC.visibility_of_element_located((locator_type, locator_value))
        price_text = price_element.text
        
        if not price_text or "R$ 0,00" in price_text:
            raise ValueError("Invalid price format")
        
        # Process price text efficiently
        current_price = (
            price_text.split()[1].replace(".","").replace(",",".")
            if "T - " in product['name']
            else price_text.replace("R$","").strip().replace(".","").replace(",",".")
        )
        print(f"  ✅ Current price: R$ {current_price}")

        # Load price data once per product
        price_data = get_price_data()
        price_history = price_data.get(product['name'], [])
        
        # Find today's entry if it exists
        today_entry = next((p for p in price_history if p['date'] == today), None)
        
        if not today_entry:
            # First check today - create new entry
            print("  📅 First check today")
            previous_price = price_history[-1]['price'] if price_history else None
            
            new_entry = {"date": today, "price": current_price}
            price_data[product['name']].append(new_entry)
            
            # Notify if price dropped from previous recording
            if previous_price and float(current_price) < float(previous_price):
                print(f"  ⬇️ Price drop from last recording! (Was: R$ {previous_price})")
                notify_discord(product['name'], current_price, previous_price)
            elif not price_history:
                notify_discord(product['name'], current_price)
            
        else:
            # Subsequent check today
            recorded_price = today_entry['price']
            if float(current_price) < float(recorded_price):
                print(f"  ⬇️ Price drop detected today! (Was: R$ {recorded_price})")
                today_entry['price'] = current_price
                notify_discord(product['name'], current_price, recorded_price)
            else:
                print("  ➖ Price unchanged or higher today")
        
        # Save data after processing
        save_price_data(price_data)
        return None  # No error
        
    except Exception as e:
        print(f"  ❌ Failed: {str(e)}")
        return product['name']

def main():
    print(f"Starting price check at {datetime.now()}")
    failed_products = []
    browser = None
    
    try:
        browser = get_browser()
        
        for product in products:
            failed_product = get_price(product, browser)
            if failed_product:
                failed_products.append(failed_product)
            
            # Clear memory between scrapes
            gc.collect()
            time.sleep(3)  # Reduced cooldown
    
    finally:
        if browser:
            try:
                browser.quit()
            except:
                os.system("pkill -f firefox")  # Force cleanup
    
    if failed_products:
        print("\n❌ Failed components:", ", ".join(failed_products))
    print("\n✅ Price check complete")

if __name__ == '__main__':
    main()
