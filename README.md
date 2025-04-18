## Configuration files for my homelab
**Running in a Raspberry Pi Zero 2**

### Services being used
- OMV (OpenMediaVault): NAS setup for file sharing and backup
- Pi-hole (with unbound): Local DNS server with filtering
- Docker: Container environment for python web scraping scripts
- TTYD: Web interface to interact with the homelab 

### Important files / directories
- pi.sh: File containing the commands used to configure the homelab
- price-tracker: Directory with the web scraping scripts and Docker container configuration files. Currently able to get the price from the following websites:
    - Amazon
    - Kabum
    - Magazine Luiza
    - Mercado Livre
    - Pichau
    - Terabyte
    - Web Continental
- scripts: Directory with bash scripts for task automation
