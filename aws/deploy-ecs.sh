#!/bin/bash

# Script para desplegar en AWS ECS
# Uso: ./aws/deploy-ecs.sh

set -e

# Variables de configuración
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
ECR_REPO_NAME="go-whatsapp-web"
ECS_CLUSTER_NAME="whatsapp-cluster"
ECS_SERVICE_NAME="whatsapp-service"
ECS_TASK_FAMILY="go-whatsapp-web"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Iniciando despliegue en AWS ECS...${NC}"

# 1. Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI no está instalado. Por favor instálalo primero.${NC}"
    exit 1
fi

# 2. Verificar Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker no está instalado. Por favor instálalo primero.${NC}"
    exit 1
fi

# 3. Construir imagen Docker
echo -e "${YELLOW}📦 Construyendo imagen Docker...${NC}"
docker build -t ${ECR_REPO_NAME}:latest .

# 4. Configurar ECR
ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"

echo -e "${YELLOW}🔐 Autenticándose en ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URI}

# 5. Crear repositorio ECR si no existe
echo -e "${YELLOW}📋 Verificando repositorio ECR...${NC}"
if ! aws ecr describe-repositories --repository-names ${ECR_REPO_NAME} --region ${AWS_REGION} &> /dev/null; then
    echo -e "${YELLOW}📋 Creando repositorio ECR...${NC}"
    aws ecr create-repository --repository-name ${ECR_REPO_NAME} --region ${AWS_REGION}
fi

# 6. Etiquetar y subir imagen
echo -e "${YELLOW}📤 Subiendo imagen a ECR...${NC}"
docker tag ${ECR_REPO_NAME}:latest ${ECR_REPO_URI}:latest
docker push ${ECR_REPO_URI}:latest

# 7. Actualizar task definition
echo -e "${YELLOW}📝 Actualizando task definition...${NC}"
TASK_DEF_FILE="aws/ecs-task-definition.json"

# Reemplazar placeholders
sed -i.bak "s|YOUR_ECR_REPO_URL|${ECR_REPO_URI}|g" ${TASK_DEF_FILE}
sed -i.bak "s|YOUR_ACCOUNT_ID|${AWS_ACCOUNT_ID}|g" ${TASK_DEF_FILE}

# Registrar task definition
TASK_DEF_ARN=$(aws ecs register-task-definition \
    --cli-input-json file://${TASK_DEF_FILE} \
    --region ${AWS_REGION} \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo -e "${GREEN}✅ Task definition registrada: ${TASK_DEF_ARN}${NC}"

# 8. Actualizar servicio ECS
echo -e "${YELLOW}🔄 Actualizando servicio ECS...${NC}"
if aws ecs describe-services --cluster ${ECS_CLUSTER_NAME} --services ${ECS_SERVICE_NAME} --region ${AWS_REGION} &> /dev/null; then
    aws ecs update-service \
        --cluster ${ECS_CLUSTER_NAME} \
        --service ${ECS_SERVICE_NAME} \
        --task-definition ${TASK_DEF_ARN} \
        --force-new-deployment \
        --region ${AWS_REGION} > /dev/null
    
    echo -e "${GREEN}✅ Servicio ECS actualizado${NC}"
    echo -e "${YELLOW}⏳ Esperando a que el servicio se estabilice...${NC}"
    
    aws ecs wait services-stable \
        --cluster ${ECS_CLUSTER_NAME} \
        --services ${ECS_SERVICE_NAME} \
        --region ${AWS_REGION}
    
    echo -e "${GREEN}✅ Servicio estabilizado${NC}"
else
    echo -e "${YELLOW}⚠️  Servicio no existe. Por favor créalo primero usando la consola AWS o terraform.${NC}"
fi

# 9. Restaurar archivo original
mv ${TASK_DEF_FILE}.bak ${TASK_DEF_FILE} 2>/dev/null || true

echo -e "${GREEN}🎉 Despliegue completado exitosamente!${NC}"

