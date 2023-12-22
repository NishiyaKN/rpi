from bs4 import BeautifulSoup
import requests
import pandas as pd

USER = 'inaba'
FILENAME = '/home/' + USER + '/rpi/auto/ba/counter_normal.txt'
AUTH_FILE = '/home/' + USER + '/.config/tk/dc'

def main():
    # Gets the page html and the table lenght, use it to compare with the last table lenght registered
    url = 'https://bluearchive.wiki/wiki/Banner_List_(Global)'
    page = requests.get(url)
    soup = BeautifulSoup(page.text, 'lxml')
    global table
    table = soup.find('table')
    global table_rows
    table_rows = table.find_all('tr')
    counter_today = len(table_rows)
    query_counter(counter_today)

def query_counter(counter_today):
    # Create file to store table length if not exists
    try:
        with open(FILENAME,"x") as f:
            print(f"Creating {FILENAME} file...")
    except Exception:
        pass

    with open(FILENAME, "r") as f:
        global file_counter
        file_counter = f.read()
        # if file_counter is empty, it will throw an error trying to parse to int
        if file_counter == "":
            print("Empty file, writing new value")
            update_counter(counter_today)
        elif int(file_counter) != counter_today: 
            print("New value found")
            update_counter(counter_today)
        else:
            print("Nothing to update")

def update_counter(counter_today):
    # Write new value and create a DataFrame
    try:
        with open(FILENAME, 'w') as f:
            f.write(str(counter_today))
            print("Updated counter")
    except Exception:
        print("Could not open file to write")
    create_dataframe()

def create_dataframe():
    # Gets table's columns name
    table_headers = table.find_all('th') # returns a bs4 object
    table_headers_text = [title.text.strip() for title in table_headers] # returns string list

    global df
    df = pd.DataFrame(columns = table_headers_text)

    # Insert each row to the DataFrame, starts by the index 1 since index 0 is the headers (column names)
    for row in table_rows[1:]:
        row_data = row.find_all('td')
        individual_row_data = [data.text.strip() for data in row_data]

        length = len(df)
        df.loc[length] = individual_row_data

    notify_discord()
    # print(df.loc[file_counter:])

def notify_discord():
    # Read authorization token from local file
    with open(AUTH_FILE,'r') as f:
        auth = f.read()

    url = 'https://discord.com/api/v9/channels/1180832500403155095/messages' 
    headers = {
            "Authorization" : auth.strip()
    }

    # Formulate the text string to be sent
    for i in range(file_counter, counter_today - 1):
        character = df.loc[i]['Character'].rstrip('rerun')
        period = df.loc[i]['Period']
        payload = {
                "content": "New banner: " + character + ". Period: " + period
        }

        res = requests.post(url, payload, headers=headers)

if __name__ == '__main__':
    main()
