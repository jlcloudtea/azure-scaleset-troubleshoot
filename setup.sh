# user="USERNAME INPUT"
read -p "Enter user: " USERNAME
# RESOURCEGROUP = "RESOURCEGROUP INPUT"
read -p "Enter ResourceGroupName: " RESOURCEGROUP

read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

az group create \
 --location westus3 \
 --name $RESOURCEGROUP
  
#---------------------------------------------------------#
# Configure the virtual machine scale set
  
az vmss create \
 --resource-group $RESOURCEGROUP \
 --name webServerScaleSet \
 --image UbuntuLTS \
 --vm-sku Standard_B1ls \
 --upgrade-policy-mode automatic \
 --admin-username $USERNAME \
 --generate-ssh-keys
  
#Apply the Custom Script Extension  
az vmss extension set \
 --publisher Microsoft.Azure.Extensions \
 --version 2.0 \
 --name CustomScript \
 --resource-group $RESOURCEGROUP \
 --vmss-name webServerScaleSet \
 --settings @customConfig.json

# Add a health probe to the load balancer
az network lb probe create \
--lb-name webServerScaleSetLB \
--resource-group $RESOURCEGROUP \
--name webServerHealth \
--port 80 \
--protocol Http \
--path /

# configure the load balancer to route HTTP traffic to the instances in the scale set
az network lb rule create \
 --resource-group $RESOURCEGROUP \
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
  --resource-group $RESOURCEGROUP \
  --name vmsetnsg

az network nsg rule create \
  --resource-group $RESOURCEGROUP \
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
  --resource-group $RESOURCEGROUP \
  --vnet-name webServerScaleSetVNET \
  --name webServerScaleSetSubnet \
  --network-security-group vmsetnsg

# Done
echo '-------------------------------------------------------------'
echo 'VM Setup Script Completed You can start the troubleshooting'
echo '-------------------------------------------------------------'
