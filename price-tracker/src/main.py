import subprocess
import time
from datetime import datetime

STORE_SCRIPTS = [
    'terabyte.py',
    'pichau.py',
    'kabum.py'
]

DELAY_BETWEEN_SCRIPTS = 30  # seconds between store scripts

def run_script(script_name):
    print(f"\n{'=' * 50}")
    print(f"🛒 STARTING {script_name.upper()} SCRAPER")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'=' * 50}\n")
    
    try:
        result = subprocess.run(
            ['python', script_name],
            check=True,
            text=True,
            capture_output=True
        )
        print(result.stdout)
        if result.stderr:
            print(f"⚠️ {script_name} errors:\n{result.stderr}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {script_name} failed with error:\n{e.stderr}")
        return False
    except Exception as e:
        print(f"🚨 Unexpected error running {script_name}: {str(e)}")
        return False

def main():
    print(f"\n{'#' * 60}")
    print(f"🏪 STARTING ALL STORE SCRAPERS")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'#' * 60}\n")
    
    for script in STORE_SCRIPTS:
        success = run_script(script)
        
        if script != STORE_SCRIPTS[-1]:  # Don't delay after last script
            delay = DELAY_BETWEEN_SCRIPTS
            print(f"\n⏳ Waiting {delay} seconds before next store...")
            time.sleep(delay)
    
    print(f"\n{'#' * 60}")
    print(f"✅ ALL SCRAPERS COMPLETED")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'#' * 60}\n")

if __name__ == "__main__":
    main()
