#/bin/bash

export RG_NAME=$1
export ENV=$2
export KEY=$3
export ARM_CLIENT_SECRET=$4

today=`date +"%y%m%d"`
uuid=`uuidgen | sed 's/-//g'`

export ARM_CLIENT_ID=$CLIENT_ID
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ARM_TENANT_ID=$TENANT_ID
export PLAN_FILE="aks.$ENV.plan.${today}-${uuid}" 

cd $AGENT_BUILDDIRECTORY/drop/Code

wget https://releases.hashicorp.com/terraform/0.11.14/terraform_0.11.14_linux_amd64.zip    
unzip terraform_0.11.14_linux_amd64.zip

./terraform init -backend=true -backend-config="access_key=$KEY" -backend-config="key=$ENV.terraform.tfstate"
./terraform plan -out="$PLAN_FILE" -var "resource_group_name=$RG_NAME" -var "client_secret=$ARM_CLIENT_SECRET" -var-file="$ENV.tfvars"
./terraform apply -auto-approve $PLAN_FILE

az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
az account set -s $ARM_SUBSCRIPTION_ID
az storage copy --source-local-path "./$PLAN_FILE" --destination-account-name $STORAGE_ACCOUNT --destination-container plans

aks=`az aks list -g $RG_NAME --query "[0].name" -o tsv`
az aks get-credentials -n $aks -g $RG_NAME
acrid=`az acr show -n $ACR_NAME -g $ACR_RG_NAME --query 'id' -o tsv`
az aks update -n $aks -g $RG_NAME --attach-acr $acrid   