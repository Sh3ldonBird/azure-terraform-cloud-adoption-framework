# Overview
The overall goal of this project is to utilize Terraform to build out a home lab within a Microsoft Azure Tenant using Microsoft Azure's CAF (Cloud Adoption Framework) best practices. 
Eventually logging of states and a CI/CD platform is to be implmented.  

The current management, subscription, and resource group infrastructure is currently built or nested underneath the following management groups as such. Azure Lighthouse is not in play at this time.  
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

When resources have been fully stood up, change managment will be done via a separate branch than main.  

# Projects to showcase  
## Documentation  
Each Terraform Azure Verified Module has stellar documentation. From them, I've started creating template files to deploy that meet my needs more closely.  
The idea is to store all pertinent information that I've used (root var files, etc.).  

The "Template-Files/Build examples/network/hub-definition-template.tf" has every option available either commented out or defined.  
Eventually the goal is to create modules from them with the templates as main.tf files with accompanying variable.tf files either in the root or a project or in the module folder.  
#  Build-out WEST US Hub network  
- root-mg/domain-mg/platform-mg/connectivity-mg/  
    - Connectivity Subscription Group (connectivity-sg)  
       - WestUS Resource Group Pool (westus-rg-pool)  
            - Networking Resource Group (westus-hub-networking-rg)  
                - USWest Hub VNET  
                  - Premium Firewall Loadout  
                  - DNS  
                  - Peering  

## Current status
The configuration needed at the moment doesn't call for a modular approach though it may later on.  

### Main.tf
- hub module has been defined to detail:
    - primary hub network
    - route table entries
    - Premium Azure Firewall
        - AzureFirewallSubnet & AzureFirewallManagementSubnet
    - The secondary hub has been commented out for the time being

### outputs.tf
- Need to edit.  
### terraform.tf
- Placeholder for CI/CD and/or backend settings.  
### variables.tf
- When the main.tf file is fully tested and provisioned i'll make it more modular.  

# Build-out corporate sites landing zones - WESTUS Corp Site 1
I'm still undecided on compute resource buildout as I'm honing in on what type of environment to build at the moment.  
    - Hacking lab?
    - Old school Web Server environment? For testing purposes, that's what I went with so far.  

## Landing Zone Hierarchy    
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

## Terraform Module Progress
### main.tf
- primarily used to create various resource groups to be called into modules
    - network-rg
    - compute-rg
    - identity-rg
    - security-rg
    - etc.
### output
- primarily used to define resource groups to be called into modules
    ? I may rework this as It may be confusing or hampering to not have the resources readily available prior to planning.
### terraform.tf
- [] Need to add in providers  
### variable.tf
- Started a master variable file to start making the entire project folder more modular.  
    - The vm_info variable will be used to create three or more VMs at a time within the computer-rg module.  
        - The documentation from "Template-Files/AVM-resources/AVM-res-compute-virtualmachine.tf" will be used to pull in pertinent build information for each VM.  
#### rg-pool(modules)/compute-rg
- Currently I've edited USWP1IISFE01.tf the most.
- I'll be building out the VM fully to then bring the variables into a root variable file. The root variable file will have the other servers listed with similar variables.
- I'll need to rewrite the modules variable file afterwards, but this way the setup will be more modular with the need for less edits later down the road.    
#### rg-pool(modules)/identity-rg
- I will be separating out what's currently in the compute-rg .tf files and defining them here.  
#### rg-pool(modules)/network-rg
- hub-to-spoke.tf defined the subnets, UDRs, peerings etc. for the corpsite01 spoke vnet. 
- eventually I want to bring it up most of the values into the root variable.tf file.  
