#!/bin/bash

# Script para construir y subir imagen a ECR para App Runner
# Uso: ./aws/deploy-apprunner.sh

set -e

# Variables de configuración
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="YOUR_ACCOUNT_ID"
ECR_REPO_NAME="go-whatsapp-web"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Preparando imagen para AWS App Runner...${NC}"

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

echo -e "${GREEN}✅ Imagen subida exitosamente a: ${ECR_REPO_URI}:latest${NC}"
echo -e "${YELLOW}📝 Ahora puedes crear o actualizar tu servicio en AWS App Runner usando esta imagen.${NC}"
echo -e "${YELLOW}   URI de la imagen: ${ECR_REPO_URI}:latest${NC}"

