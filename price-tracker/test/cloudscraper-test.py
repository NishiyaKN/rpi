import cloudscraper
from bs4 import BeautifulSoup

def scrape_page(url):
    # Create a cloudscraper instance
    scraper = cloudscraper.create_scraper()
    
    try:
        # Make the request
        print(f"Fetching URL: {url}")
        response = scraper.get(url)
        
        # Check if the request was successful
        if response.status_code == 200:
            print("\nSuccessfully fetched the page!\n")
            
            # Parse the HTML with BeautifulSoup
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Print all headers (h1-h6)
            print("Headers found on the page:")
            print("-" * 50)
            for header in soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6']):
                print(f"{header.name.upper()}: {header.text.strip()}")
            print("-" * 50)
            
            # You can also print the entire page content if needed
            # print("Full page content:")
            # print("-" * 50)
            # print(response.text)
            # print("-" * 50)
        else:
            print(f"Failed to fetch page. Status code: {response.status_code}")
            
    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    # URL to scrape
    target_url = "https://www.terabyteshop.com.br/produto/23095/memoria-ddr4-kingston-fury-superframe-8gb-3200mhz-black-kf432c16bb8cl"
    
    # Call the scraping function
    scrape_page(target_url)
