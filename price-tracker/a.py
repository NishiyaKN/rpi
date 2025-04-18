import requests
from bs4 import BeautifulSoup

# URL of the webpage you want to scrape
url = 'https://example.com'  # Replace with the target URL

# Send a GET request to the website
response = requests.get(url)

# Check if the request was successful (status code 200)
if response.status_code == 200:
    print("Successfully retrieved the page!")
    
    # Parse the page content with BeautifulSoup
    soup = BeautifulSoup(response.content, 'html.parser')

    # Extract all headings (h1, h2, h3, etc.)
    headings = soup.find_all(['h1', 'h2', 'h3', 'h4', 'h5', 'h6'])

    # Loop through the headings and print them
    for heading in headings:
        print(f"{heading.name}: {heading.text.strip()}")
else:
    print(f"Failed to retrieve the page. Status code: {response.status_code}")
