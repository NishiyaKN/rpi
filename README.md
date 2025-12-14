## Configuration files for my homelab
**Running in a Raspberry Pi Zero 2**

### Services being used
- OpenMediaVault: NAS setup for file sharing and backup
- Pi-hole (with unbound): Local DNS server with filtering
- PiVPN: Private connection from mobile phone to the server
- Docker: Container environment for python web scraping scripts
- TTYD: Web interface to interact with the homelab
- Transmission: Torrent client 

### Important files / directories
- pi.sh: Documentation of my homelab configuration
- price-tracker: Directory with the web scraping scripts and Docker container configuration files. Currently able to get the price from the following websites:
    - Amazon
    - Kabum
    - Magazine Luiza
    - Mercado Livre
    - Pichau
    - Terabyte
    - Web Continental
- scripts: Directory with bash scripts for task automation
