# user="USERNAME INPUT"
read -p "Enter user: " USERNAME
# PASSWORD = "PASSWORD INPUT"
read -p "Enter password: " PASSWORD
# RESOURCEGROUP = "RESOURCEGROUP INPUT"
read -p "Enter ResourceGroupName: " RESOURCEGROUP

read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

az group create \
  --location westus3 \
  --name ScaleDemo
  
  
 #6. carete VM scale set
 
 az vmss create \
  --resource-group ScaleDemo \
  --name webServerScaleSet \
  --image UbuntuLTS \
  --upgrade-policy-mode automatic \
  --custom-data cloud-init.yaml \
  --admin-username azureuser \
  --generate-ssh-keys
  
  #---------------------------------------------------------#
  # Configure the virtual machine scale set
  
  # 1. add a health probe to the load balancer
  az network lb probe create \
  --lb-name webServerScaleSetLB \
  --resource-group ScaleDemo \
  --name webServerHealth \
  --port 80 \
  --protocol Http \
  --path /
  
  # 2. configure the load balancer to route HTTP traffic to the instances in the scale set
  az network lb rule create \
  --resource-group ScaleDemo \
  --name webServerLoadBalancerRuleWeb \
  --lb-name webServerScaleSetLB \
  --probe-name webServerHealth \
  --backend-pool-name webServerScaleSetLBBEPool \
  --backend-port 80 \
  --frontend-ip-name loadBalancerFrontEnd \
  --frontend-port 80 \
  --protocol tcp
  
  # Done
echo '-------------------------------------------------------------'
echo 'VM Setup Script Completed You can start the troubleshooting'
echo '-------------------------------------------------------------'
  
