az group create \
 --location westus3 \
 --name troubleshoot
  
#---------------------------------------------------------#
# Configure the virtual machine scale set
  
az vmss create \
 --resource-group troubleshoot \
 --name webServerScaleSet \
 --image UbuntuLTS \
 --vm-sku Standard_B1ls \
 --upgrade-policy-mode automatic \
 --admin-username azureuser \
 --generate-ssh-keys
  
#Apply the Custom Script Extension  
az vmss extension set \
 --publisher Microsoft.Azure.Extensions \
 --version 2.0 \
 --name CustomScript \
 --resource-group troubleshoot \
 --vmss-name webServerScaleSet \
 --settings @customConfig.json

# Add a health probe to the load balancer
az network lb probe create \
--lb-name webServerScaleSetLB \
--resource-group troubleshoot \
--name webServerHealth \
--port 80 \
--protocol Http \
--path /

# configure the load balancer to route HTTP traffic to the instances in the scale set
az network lb rule create \
 --resource-group troubleshoot \
 --name webServerLoadBalancerRuleWeb \
 --lb-name webServerScaleSetLB \
 --probe-name webServerHealth \
 --backend-pool-name webServerScaleSetLBBEPool \
 --backend-port 80 \
 --frontend-ip-name loadBalancerFrontEnd \
 --frontend-port 80 \
 --protocol tcp

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
  --vnet-name webServerScaleSetVNET \
  --name webServerScaleSetSubnet \
  --network-security-group vmsetnsg
  
#update the existing vm
InstanceId=`az vmss list-instances -g troubleshoot -n webServerScaleSet --query '[0].instanceId' --output tsv`
az vmss stop --resource-group troubleshoot --name webServerScaleSet --instance-ids $InstanceId

# Done
echo '--------------------------------------------------------------------'
echo ' VM Setup Script Completed !                                        '                        
echo ' You can start the troubleshooting in resource group "troubleshoot" '
echo '--------------------------------------------------------------------'
