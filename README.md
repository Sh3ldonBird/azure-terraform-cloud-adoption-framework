# Overview
The current management, subscription, and resource group infrastructure is currently built or nested underneath the following management groups as such. Azure Lighthouse is noit in play at this time.  
Review Microsoft Azure Landing Zone Deployment for a better understanding on the lines of division.  
https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/   

- Root Management Group
    - Domain Management Group
        - Decommissioned Management Group
        - Landing Zones Management Group
            - Corporate Management Group
            - Online Management Group
        - Platform Management Group
            - Connectivity Management Group
            - Identity Management Group
            - Management Management Group
        - Sandbox Management Group

# Projects to showcase
- Build-out, connectivity, & day to day activities between USWEST VNet Connectivity hub and a corporate site within the USWest region.
- Build-out, connectivity, & day to day activities with the USWest MS Sentinel Instance.
- Azure Function load-out for pulling in specific logs via data connectors into MS Sentinel.

Each deployment will be done via Terraform.  
Eventually logging of states and a CI/CD platform is to be implmented.  
## USWEST VNet Connectivity hub and USWest corporate site

### USWest Connectivity Hub 

- Connectivity Subscription Group
   - USWest Resource Group Pool
        - Networking Resource Group
            - USWest Hub VNET
              - Premium Firewall Loadout
              - DNS
              - Peering

### USWEST Corp Site 1

- Landing zone applications Subscription Group
    - Corp Site Resource Group Pool
        - Network Resource Group
            - USWest Spoke VNet Configurations
        - Compute Resource Group
            - App Server VM Configuration
            - Web Server VM Configuration
            - Database Server VM Configuration
        - Security Resource Group
            - MS Sentinel
            - Log Anaylytic Workspace
## USWest MS Sentinel

## USWEST MS Sentinel Lops
