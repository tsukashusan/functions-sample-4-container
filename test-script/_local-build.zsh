DOCKER_ID=<your_docker_id>
# Replace <your_docker_id> with your actual Docker ID
REGISTRY_NAME=<your_registry_name>
# Replace <your_registry_name> with your actual Azure Container Registry name
TENANT_ID=<your_tenant_id>
# Replace <your_tenant_id> with your actual Azure tenant ID
SUBSCRIPTION_ID=<your_subscription_id>
# Replace <your_subscription_id> with your actual Azure subscription ID
RESOURCE_GROUP_NAME=<your_resource_group_name>
# Replace <your_resource_group_name> with your desired resource group name
LOGIN_SERVER=<your_registry_name>.azurecr.io
# Replace <your_registry_name> with your actual Azure Container Registry name
IMAGE_NAME=<your_image_name>
# Replace <your_image_name> with your desired image name
TAG=<your_image_tag>
# Replace <your_image_tag> with your desired image tag

docker build --tag ${DOCKER_ID}/${IMAGE_NAME}:${TAG} .

docker run -p 8080:80 -it ${DOCKER_ID}/${IMAGE_NAME}:${TAG}

az login --tenant ${TENANT_ID}
az account set --subscription ${SUBSCRIPTION_ID}

az acr create --resource-group ${RESOURCE_GROUP_NAME} \
--name ${REGISTRY_NAME} --sku Standard --role-assignment-mode 'rbac-abac' --dnl-scope TenantReuse

az acr login --name ${REGISTRY_NAME}

docker tag ${DOCKER_ID}/${IMAGE_NAME}:${TAG} ${LOGIN_SERVER}/${IMAGE_NAME}:${TAG}
docker push ${LOGIN_SERVER}/${IMAGE_NAME}:${TAG}

az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

RESOURCE_GROUP_NAME=<your_resource_group_name>
# Replace <your_resource_group_name> with your desired resource group name
CONTAINER_APP_NAME=<your_container_app_name>
# Replace <your_container_app_name> with your desired container app name
CONTAINERAPPS_ENVIRONMENT=<your_containerapps_environment>
# Replace <your_containerapps_environment> with your desired container apps environment name
LOCATION=<your_location>
# Replace <your_location> with your desired Azure region, e.g., "japaneast"
# Ensure the location matches your Azure Container Registry location
IDENTITY=<your_identity_name>
# Replace <your_identity_name> with your desired identity name  

az group create --name ${RESOURCE_GROUP_NAME} --location ${LOCATION}
az identity create \
  --name ${IDENTITY} \
  --resource-group ${RESOURCE_GROUP_NAME} \
  --location ${LOCATION}

IDENTITY_OBJECT_ID=$(az identity show --name ${IDENTITY} --resource-group ${RESOURCE_GROUP_NAME} --query principalId --output tsv)
IDENTITY_ID=$(az identity show --name ${IDENTITY} --resource-group ${RESOURCE_GROUP_NAME} --query id --output tsv)


az role assignment create --assignee-principal-type ServicePrincipal --assignee-object-id ${IDENTITY_OBJECT_ID} \
  --role "Container Registry Repository Reader" \
  --scope /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.ContainerRegistry/registries/${REGISTRY_NAME}

az containerapp env create --name ${CONTAINERAPPS_ENVIRONMENT} --resource-group ${RESOURCE_GROUP_NAME} --location ${LOCATION}

$appsFQDN= $(az containerapp create \
--name ${CONTAINER_APP_NAME} \
--resource-group ${RESOURCE_GROUP_NAME} \
--environment ${CONTAINERAPPS_ENVIRONMENT} \
--ingress external \
--target-port 80 \
--kind functionapp \
--registry-server "${REGISTRY_NAME}.azurecr.io" \
--image "${REGISTRY_NAME}.azurecr.io/${IMAGE_NAME}:${TAG}"\
--query properties.configuration.ingress.fqdn)

az containerapp identity assign -n ${CONTAINER_APP_NAME} -g ${RESOURCE_GROUP_NAME} --system-assigned
az containerapp identity show -n ${CONTAINER_APP_NAME} -g ${RESOURCE_GROUP_NAME}
