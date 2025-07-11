DOCKER_ID=shtsukam
REGISTRY_NAME=mlcontainerregst
TENANT_ID=16b3c013-d300-468d-ac64-7eda0820b6d3
SUBSCRIPTION_ID=be7d3851-09f6-433c-8da5-09aace58dcd2
RESOURCE_GROUP_NAME=containerapp-rg
LOGIN_SERVER=mlcontainerregst.azurecr.io
IMAGE_NAME=azurefunctionsimage
TAG=v1.0.1

docker build --tag ${DOCKER_ID}/${IMAGE_NAME}:${TAG} .

docker run -p 8080:80 -it ${DOCKER_ID}/${IMAGE_NAME}:${TAG}


az login --tenant ${TENANT_ID}
az account set --subscription ${SUBSCRIPTION_ID}

az acr create --resource-group ${RESOURCE_GROUP_NAME} \
--name ${REGISTRY_NAME} --sku Standard --role-assignment-mode 'rbac-abac' --dnl-scope TenantReuse

az acr login --name ${REGISTRY_NAME}
docker build --tag ${DOCKER_ID}/${IMAGE_NAME}:${TAG} .
docker tag ${DOCKER_ID}/${IMAGE_NAME}:${TAG} ${LOGIN_SERVER}/${IMAGE_NAME}:${TAG}
docker push ${LOGIN_SERVER}/${IMAGE_NAME}:${TAG}

az extension add --name containerapp --upgrade
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights

CONTAINER_APP_NAME=shtsukam-containerapp
CONTAINERAPPS_ENVIRONMENT="shtsukam-aca-functions-environment"
LOCATION="japaneast"
IDENTITY="containerapp-identity"

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

az containerapp create \
--name ${CONTAINER_APP_NAME} \
--resource-group ${RESOURCE_GROUP_NAME} \
--environment ${CONTAINERAPPS_ENVIRONMENT} \
--ingress external \
--target-port 80 \
--kind functionapp \
--registry-server "${REGISTRY_NAME}.azurecr.io" \
--image "${REGISTRY_NAME}.azurecr.io/${IMAGE_NAME}:${TAG}"\
--env-vars $(tr "\n" " "< .env) \
--query properties.configuration.ingress.fqdn

# Uncomment the following line to update the container app with the new image and environment variables
#az containerapp update -n ${CONTAINER_APP_NAME} -g ${RESOURCE_GROUP_NAME} --image ${REGISTRY_NAME}.azurecr.io/${IMAGE_NAME}:${TAG} --set-env-vars $(tr "\n" " "< .env)

az containerapp identity assign -n ${CONTAINER_APP_NAME} -g ${RESOURCE_GROUP_NAME} --system-assigned
az containerapp identity show -n ${CONTAINER_APP_NAME} -g ${RESOURCE_GROUP_NAME}
