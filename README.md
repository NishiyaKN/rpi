## Configuration files for my homelab
**Running in a Raspberry Pi Zero 2**

### Services being used
- OpenMediaVault: NAS setup for file sharing and backup
- Pi-hole (with unbound): Local DNS server with filtering
- PiVPN: Private connection from mobile phone to the server
- Docker: Container environment for python web scraping scripts
- TTYD: Web interface to interact with the homelab
- Transmission: Torrent client

### System Architecture
```mermaid
graph TDgraph TD

    subgraph Internet
        Phone["Smartphone (Remote)"]:::ext
        Laptop["Laptop (Remote)"]:::ext
    end

    subgraph "Home Network"
        Router["Router"]:::hardware
        
        subgraph "Iroha (Raspberry Pi Zero 2)"
            direction TB
            
            subgraph "Docker Stack"
                WG["WireGuard VPN"]:::docker
                HM["Homer Dashboard"]:::docker
                PH["️Pi-hole DNS"]:::docker
                UN["Unbound"]:::docker
                FB["File Browser"]:::docker
                DZ["Dozzle"]:::docker
                OST["OpenSpeedTest"]:::docker
                TR["Transmission"]:::docker
                ST["Syncthing"]:::docker
                WT["Watchtower"]:::docker
                DK["Doku"]:::docker
            end

            subgraph "Bare Metal Services"
                SMB["SMB"]:::baremetal
                TTYD["TTYD"]:::baremetal
            end 
            %%SSD["Storage"]:::hardware
        end
    end

    %% Connections
    Phone -->|VPN Tunnel| Router
    Laptop -->|VPN Tunnel| Router
    Router -->|51820| WG
    
    %% Internal Docker Routing
    WG --> |80| HM
    WG --> |81| PH
    PH --> |5335| UN
    WG --> |82| FB
    WG --> |83| DZ
    WG --> |84| DK
    WG --> |8384| ST
    WG --> |9091| TR

    WG --> |3000| OST
    WG --> |7681| TTYD
    
    %% Storage Access
    %%TR -->|Read/Write| SSD
    %%FB -->|Manage Files| SSD
    %%SMB -->|File Share| SSD

    subgraph Internet
        Phone["Smartphone (Remote)"]:::ext
        Laptop["Laptop (Remote)"]:::ext
    end

    subgraph "Home Network"
        Router["Router"]:::hardware
        
        subgraph "Iroha (Raspberry Pi Zero 2)"
            direction TB
            
            subgraph "Docker Stack"
                WG["WireGuard VPN"]:::docker
                HM["Homer Dashboard"]:::docker
                PH["️Pi-hole DNS"]:::docker
                UN["Unbound"]:::docker
                FB["File Browser"]:::docker
                DZ["Dozzle"]:::docker
                OST["OpenSpeedTest"]:::docker
                TR["Transmission"]:::docker
                ST["Syncthing"]:::docker
                WT["Watchtower"]:::docker
                DK["Doku"]:::docker
            end

            subgraph "Bare Metal Services"
                SMB["SMB"]:::baremetal
                TTYD["TTYD"]:::baremetal
            end 
            %%SSD["Storage"]:::hardware
        end
    end

    %% Connections
    Phone -->|VPN Tunnel| Router
    Laptop -->|VPN Tunnel| Router
    Router -->|51820| WG
    
    %% Internal Docker Routing
    WG --> |80| HM
    WG --> |81| PH
    PH --> |5335| UN
    WG --> |82| FB
    WG --> |83| DZ
    WG --> |84| DK
    WG --> |8384| ST
    WG --> |9091| TR

    WG --> |3000| OST
    WG --> |7681| TTYD
    
    %% Storage Access
    %%TR -->|Read/Write| SSD
    %%FB -->|Manage Files| SSD
    %%SMB -->|File Share| SSD

```

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
