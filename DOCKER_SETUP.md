# Docker Development Setup

Bu proje, development ortamını Docker ile çalıştırmak için yapılandırılmıştır.

## Gereksinimler

- Docker & Docker Compose
- Supabase CLI (`npm install -g supabase`)
- Node.js 20+ (Supabase CLI için)

## Hızlı Başlangıç

### 1. Environment Dosyasını Hazırlayın

`backend/.env` dosyasının mevcut olduğundan emin olun:

```bash
cd backend
cp .env.example .env
# .env dosyasını düzenleyin ve Supabase bilgilerinizi girin
```

### 2. Development Ortamını Başlatın

```bash
# Script'i çalıştırılabilir yapın (ilk sefer)
chmod +x start-dev.sh

# Tüm servisleri başlatın
./start-dev.sh
```

Script otomatik olarak:
- Supabase'in çalışıp çalışmadığını kontrol eder
- Çalışmıyorsa Supabase'i başlatır
- Docker Compose ile backend ve gateway'i başlatır

## Servisler

### Backend (Fastify)
- **Port:** `3000`
- **Hot Reload:** ✅ Aktif (kod değişiklikleri otomatik yansır)
- **Volume:** `./backend` → `/app` (kod değişiklikleri anında yansır)

### Gateway (Nginx)
- **Port:** `8080`
- **Routes:**
  - `/rest/`, `/auth/`, `/storage/` → Supabase (`host.docker.internal:54321`)
  - `/payment/`, `/api/`, `/webhook/` → Backend (`backend:3000`)

### Supabase
- **Port:** `54321` (host makinede çalışır)
- **Studio:** `http://127.0.0.1:54323`

## Kullanım

### Backend API'ye Erişim

Gateway üzerinden:
```bash
curl http://localhost:8080/api/health
```

Doğrudan backend:
```bash
curl http://localhost:3000/health
```

### Supabase API'ye Erişim

Gateway üzerinden:
```bash
curl http://localhost:8080/rest/v1/categories
```

### Servisleri Durdurma

```bash
docker-compose -f docker-compose.dev.yml down
```

### Logları Görüntüleme

```bash
# Tüm servisler
docker-compose -f docker-compose.dev.yml logs -f

# Sadece backend
docker-compose -f docker-compose.dev.yml logs -f backend

# Sadece gateway
docker-compose -f docker-compose.dev.yml logs -f gateway
```

## Sorun Giderme

### Port Çakışması

Eğer portlar kullanılıyorsa, `docker-compose.dev.yml` dosyasındaki port numaralarını değiştirin.

### Supabase Bağlantı Sorunu

`host.docker.internal` bazı Linux sistemlerde çalışmayabilir. Bu durumda:
1. Host makinenin IP adresini bulun
2. `docker-compose.dev.yml` içinde `host.docker.internal` yerine IP adresini kullanın

### Hot Reload Çalışmıyor

- Volume mount'un doğru olduğundan emin olun
- `backend/Dockerfile.dev` içinde `CMD` komutunun `pnpm run dev` olduğunu kontrol edin
- Container loglarını kontrol edin: `docker-compose logs backend`

## Yapı

```
.
├── backend/
│   ├── Dockerfile.dev      # Development Dockerfile
│   ├── .dockerignore       # Docker ignore dosyası
│   └── .env                # Environment variables
├── gateway/
│   └── nginx.conf          # Nginx gateway konfigürasyonu
├── docker-compose.dev.yml  # Docker Compose konfigürasyonu
└── start-dev.sh            # Başlatma scripti
```

