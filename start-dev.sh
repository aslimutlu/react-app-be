#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Development environment başlatılıyor...${NC}"

# Check if Supabase is running
echo -e "${YELLOW}📊 Supabase durumu kontrol ediliyor...${NC}"
if ! npx supabase status > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Supabase çalışmıyor, başlatılıyor...${NC}"
    npx supabase start
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Supabase başlatılamadı!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Supabase başlatıldı${NC}"
else
    echo -e "${GREEN}✅ Supabase zaten çalışıyor${NC}"
fi

# Check if .env file exists in backend
if [ ! -f "./backend/.env" ]; then
    echo -e "${YELLOW}⚠️  backend/.env dosyası bulunamadı!${NC}"
    echo -e "${YELLOW}   Lütfen backend/.env dosyasını oluşturun.${NC}"
    echo -e "${YELLOW}   Örnek: cp backend/.env.example backend/.env${NC}"
    exit 1
fi

# Start Docker Compose
echo -e "${YELLOW}🐳 Docker Compose başlatılıyor...${NC}"
docker-compose -f docker-compose.dev.yml up --build

