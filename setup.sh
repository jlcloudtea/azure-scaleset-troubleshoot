#!/bin/bash
az group create \
 --location eastus \
 --name troubleshoot

#---------------------------------------------------------#
# Configure the virtual machine scale set
  
az vmss create \
  --resource-group troubleshoot \
  --name TRScaleSet \
  --image Ubuntu2204 \
  --orchestration-mode Flexible \
  --admin-username azureuser \
  --generate-ssh-keys
  
#Apply the Custom Script Extension  
az vmss extension set \
 --publisher Microsoft.Azure.Extensions \
 --version 2.0 \
 --name CustomScript \
 --resource-group troubleshoot \
 --vmss-name TRScaleSet \
 --settings @customConfig.json

#Apply the extension to the existing scale set instances
az vmss update-instances \
 --resource-group troubleshoot \
 --name TRScaleSet \
 --instance-ids "*"

#Allow traffic to port 80
az network nsg rule create \
 --name AllowHTTP \
 --resource-group troubleshoot \
 --nsg-name TRScaleSetNSG \
 --access Allow \
 --priority 1010 \
 --destination-port-ranges 80

#Test your scale set
echo 'PublicIP of LoadBalance is'
az network public-ip show \
--resource-group troubleshoot \
--name TRScaleSetLBPublicIP \
--query [ipAddress] \
--output tsv

# Setup "Environment"
az network nsg create \
  --resource-group troubleshoot \
  --name vmsetnsg

az network nsg rule create \
  --resource-group troubleshoot \
  --name vmsetnsgrule \
  --nsg-name vmsetnsg \
  --protocol tcp \
  --direction inbound \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix 'VirtualNetwork' \
  --destination-port-range '*' \
  --access deny \
  --priority 110
  
#update the existing subnet
az network vnet subnet update \
  --resource-group troubleshoot \
  --vnet-name TRScaleSetVNET \
  --name TRScaleSetSubnet \
  --network-security-group vmsetnsg
  
#update the existing vm
InstanceId=`az vmss list-instances -g troubleshoot -n TRScaleSet --query '[0].instanceId' --output tsv`
az vmss stop --resource-group troubleshoot --name TRScaleSet --instance-ids $InstanceId

# Done
echo '--------------------------------------------------------------------'
echo ' VM Setup Script Completed !                                        '                        
echo ' You can start the troubleshooting in resource group "troubleshoot" '
echo '--------------------------------------------------------------------'
