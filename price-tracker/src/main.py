import subprocess
import time
from datetime import datetime

ACTIVE_SCRIPTS_FILE = 'active.conf'  # File containing list of scripts to run
DELAY_BETWEEN_SCRIPTS = 30  # seconds between store scripts

def get_active_scripts():
    """Read the active scripts file and return a list of scripts to run, ignoring comments and empty lines."""
    try:
        with open(ACTIVE_SCRIPTS_FILE, 'r') as f:
            scripts = []
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):  # Ignore empty lines and comments
                    scripts.append(line)
            return scripts
    except FileNotFoundError:
        print(f"❌ Error: Could not find {ACTIVE_SCRIPTS_FILE} file")
        return []
    except Exception as e:
        print(f"❌ Error reading {ACTIVE_SCRIPTS_FILE}: {str(e)}")
        return []

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
    store_scripts = get_active_scripts()
    
    if not store_scripts:
        print("⛔ No active scripts found to run. Exiting.")
        return
    
    print(f"\n{'#' * 60}")
    print(f"🏪 STARTING ALL STORE SCRAPERS")
    print(f"📋 Active scripts: {', '.join(store_scripts)}")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'#' * 60}\n")
    
    for script in store_scripts:
        success = run_script(script)
        
        if script != store_scripts[-1]:  # Don't delay after last script
            delay = DELAY_BETWEEN_SCRIPTS
            print(f"\n⏳ Waiting {delay} seconds before next store...")
            time.sleep(delay)
    
    print(f"\n{'#' * 60}")
    print(f"✅ ALL SCRAPERS COMPLETED")
    print(f"⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'#' * 60}\n")

if __name__ == "__main__":
    main()
