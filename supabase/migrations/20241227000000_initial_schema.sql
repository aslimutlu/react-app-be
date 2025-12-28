-- ============================================================================
-- Supabase (PostgreSQL) Veritabanı Şeması
-- Mobil Uygulama: React Native Eğitim Uygulaması
-- ============================================================================

-- ============================================================================
-- STORAGE BUCKET STANDARD: Dosyalar şu yolda saklanmalıdır:
-- {category_slug}/{content_slug}/{type}/{filename}.ext
-- Örnek: stories/kirmizi-baslikli-kiz/audio/main.mp3
-- Örnek: games/coloring-time/images/template.svg
-- Örnek: cards/animals/images/duck.png
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. KULLANICI YÖNETİMİ
-- ============================================================================

-- Çocuk profilleri tablosu (AuthContext'teki ChildProfile)
-- ProfilesScreen'de yönetilen çocuk profilleri
-- NOT: user_id, Supabase'in auth.users tablosundaki id'yi referans alır
CREATE TABLE child_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- Profil ismi
    avatar_type TEXT NOT NULL CHECK (avatar_type IN ('boy', 'girl')), -- Avatar tipi
    background_color TEXT NOT NULL, -- Profil arka plan rengi (örn: 'bg-blue-100')
    is_active BOOLEAN DEFAULT false, -- Aktif profil mi? (HomeScreen'de gösterilen)
    deleted_at TIMESTAMPTZ, -- Soft delete: Arşivleme için
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 2. İÇERİK YÖNETİMİ
-- ============================================================================

-- Kategori tipleri enum'u
CREATE TYPE category_type AS ENUM ('card', 'story', 'play', 'awareness', 'bedtime');

-- İçerik tipleri enum'u (tüm içerikler için: hikayeler, oyunlar, kartlar vb.)
CREATE TYPE content_type AS ENUM (
    'story',           -- Hikayeler
    'card',            -- Kartlar
    'game-coloring',   -- Boyama oyunu
    'game-matching',   -- Eşleştirme oyunu
    'game-counting',   -- Sayma oyunu (how_many, count_and_burst)
    'game-drawing',    -- Çizim oyunu (draw_together)
    'game-find-shape', -- Şekil bulma oyunu
    'game-what-hear',  -- Ne duyuyorsun oyunu
    'awareness',       -- Farkındalık içerikleri
    'bedtime'          -- Uyku vakti içerikleri
);

-- Kategoriler tablosu (constants/categories.ts'deki kategoriler)
-- CategoriesScreen'de gösterilen ana kategoriler
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type category_type NOT NULL, -- Kategori tipi
    key TEXT UNIQUE NOT NULL, -- Kategori key'i (örn: 'animals', 'lost_smiles')
    name TEXT NOT NULL, -- Kategori adı (örn: 'Hayvanlar', 'Kaybolan Gülümsemeler')
    description TEXT, -- Kategori açıklaması
    image_url TEXT, -- Kategori görsel URL'i
    background_image_url TEXT, -- Arka plan görseli (story/awareness için)
    background_color TEXT, -- Tailwind class (örn: 'bg-green-400')
    show_item_image BOOLEAN DEFAULT true, -- Görsel gösterilsin mi?
    text_position TEXT, -- Metin pozisyonu ('bottom', 'top', 'center')
    text_orientation TEXT, -- Metin yönelimi ('horizontal', 'vertical')
    text_size TEXT, -- Metin boyutu ('small', 'medium', 'large')
    display_order INTEGER DEFAULT 0, -- Görüntülenme sırası
    deleted_at TIMESTAMPTZ, -- Soft delete: Arşivleme için
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- İçerikler tablosu (Hikayeler, Kartlar, Oyunlar, Farkındalık, Uyku Vakti)
-- BookReadingScreen, CardCategoriesDetailScreen, AwarenessCategoriesDetailScreen, 
-- BedtimeCategoriesDetailScreen, ColoringGameScreen, DrawTogetherScreen vb. için
-- NOT: games tablosu kaldırıldı, tüm oyunlar bu tabloda tutuluyor
CREATE TABLE contents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    type content_type NOT NULL, -- İçerik tipi (story, game-coloring, card vb.)
    title TEXT NOT NULL, -- İçerik başlığı
    slug TEXT, -- URL-friendly slug (storage path için)
    image_url TEXT, -- İçerik görseli
    background_image_url TEXT, -- Arka plan görseli (hikayeler için)
    audio_file_url TEXT, -- Ses dosyası URL'i (BookReadingScreen, AwarenessCategoriesDetailScreen için)
    text_content TEXT, -- Metin içeriği (hikaye metni, kart açıklaması vb.)
    capture_text TEXT, -- Ekranda gösterilen metin (typewriter effect için)
    display_order INTEGER DEFAULT 0, -- Görüntülenme sırası (sayfa numarası gibi)
    metadata JSONB, -- Ekstra metadata (SVG ID, zorluk seviyesi, renk paleti, oyun konfigürasyonları vb.)
    -- Örnek metadata yapısı:
    -- Oyunlar için: {"svg_id": "template-1", "difficulty": "easy", "instructions": "...", "color_palette": [...]}
    -- Hikayeler için: {"page_count": 10, "duration_minutes": 5}
    deleted_at TIMESTAMPTZ, -- Soft delete: Arşivleme için
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 3. KULLANICI ETKİLEŞİMLERİ
-- ============================================================================

-- Favoriler tablosu
-- HomeScreen'deki "En Sevilen Kartlar" için
CREATE TABLE favorites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_profile_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    content_id UUID REFERENCES contents(id) ON DELETE CASCADE,
    favorite_type TEXT NOT NULL CHECK (favorite_type IN ('category', 'content')), -- Favori tipi
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_favorite_per_profile UNIQUE (child_profile_id, category_id, content_id, favorite_type)
);

-- ============================================================================
-- 4. AYARLAR VE EBEVEYN KONTROLÜ
-- ============================================================================

-- Kullanıcı ayarları tablosu
-- SettingsScreen'deki tüm ayarlar
-- NOT: user_id, Supabase'in auth.users tablosundaki id'yi referans alır
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    notifications_enabled BOOLEAN DEFAULT true, -- Bildirimler açık/kapalı
    game_sounds_enabled BOOLEAN DEFAULT true, -- Oyun sesleri açık/kapalı
    music_enabled BOOLEAN DEFAULT false, -- Müzik açık/kapalı
    language TEXT DEFAULT 'tr' CHECK (language IN ('tr', 'en')), -- Dil tercihi
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_settings_per_user UNIQUE (user_id)
);

-- Profil bazlı zaman sınırları
-- TimeLimitScreen'deki ayarlar
CREATE TABLE profile_time_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_profile_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    daily_limit_minutes INTEGER DEFAULT 120, -- Günlük kullanım süresi (dakika)
    banned_start_time TIME, -- Yasaklı saat başlangıcı (örn: '22:00')
    banned_end_time TIME, -- Yasaklı saat bitişi (örn: '07:00')
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_time_limit_per_profile UNIQUE (child_profile_id)
);

-- Günlük kullanım kayıtları
-- TimeLimitScreen'deki "Bugünkü Kullanım" için
CREATE TABLE daily_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_profile_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    usage_date DATE NOT NULL, -- Kullanım tarihi
    total_minutes INTEGER DEFAULT 0, -- Toplam kullanım süresi (dakika)
    session_count INTEGER DEFAULT 0, -- Oturum sayısı
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_daily_log_per_profile UNIQUE (child_profile_id, usage_date)
);

-- ============================================================================
-- 5. ABONELİK YÖNETİMİ
-- ============================================================================

-- Abonelik planları tablosu
-- PlansScreen'deki plan seçenekleri
CREATE TABLE subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_key TEXT UNIQUE NOT NULL, -- Plan key'i ('yearly', 'sixmonth', 'monthly')
    title TEXT NOT NULL, -- Plan adı ('Yıllık', '6 Aylık', 'Aylık')
    price DECIMAL(10,2) NOT NULL, -- Plan fiyatı
    period_price DECIMAL(10,2) NOT NULL, -- Aylık eşdeğer fiyat
    period_unit TEXT NOT NULL, -- Periyot birimi ('aylık')
    duration_months INTEGER NOT NULL, -- Süre (ay cinsinden)
    features JSONB, -- Plan özellikleri (FEATURES array'i)
    is_active BOOLEAN DEFAULT true, -- Plan aktif mi?
    display_order INTEGER DEFAULT 0, -- Görüntülenme sırası
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Kullanıcı abonelikleri tablosu
-- ManageSubscriptionScreen için
-- NOT: user_id, Supabase'in auth.users tablosundaki id'yi referans alır
CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'expired')), -- Abonelik durumu
    start_date DATE NOT NULL, -- Başlangıç tarihi
    end_date DATE, -- Bitiş tarihi (null ise süresiz)
    next_payment_date DATE, -- Sonraki ödeme tarihi
    auto_renewal BOOLEAN DEFAULT true, -- Otomatik yenileme açık mı?
    payment_method TEXT, -- Ödeme yöntemi
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ödeme geçmişi tablosu
-- ManageSubscriptionScreen'deki "Fatura Geçmişi" için
CREATE TABLE payment_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL, -- Ödeme tutarı
    payment_date DATE NOT NULL, -- Ödeme tarihi
    payment_method TEXT, -- Ödeme yöntemi
    transaction_id TEXT, -- İşlem ID'si (ödeme gateway'den)
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'refunded')), -- Ödeme durumu
    invoice_url TEXT, -- Fatura URL'i
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 6. GERİ BİLDİRİM VE DESTEK
-- ============================================================================

-- Geri bildirimler tablosu
-- FeedbackScreen için
-- NOT: user_id, Supabase'in auth.users tablosundaki id'yi referans alır
CREATE TABLE feedbacks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    child_profile_id UUID REFERENCES child_profiles(id) ON DELETE SET NULL,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5), -- Yıldız puanı (1-5)
    feedback_text TEXT, -- Geri bildirim metni
    feedback_type TEXT CHECK (feedback_type IN ('general', 'bug', 'suggestion', 'complaint')), -- Geri bildirim tipi
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved')), -- Durum
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 7. EBEVEYN DOĞRULAMA
-- ============================================================================

-- Ebeveyn doğrulama kayıtları
-- ParentalVerificationScreen için
-- NOT: user_id, Supabase'in auth.users tablosundaki id'yi referans alır
CREATE TABLE parental_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    verification_type TEXT NOT NULL CHECK (verification_type IN ('math_question', 'pin', 'password')), -- Doğrulama tipi
    question_data JSONB, -- Soru verileri (math question için: num1, num2, operation, answer)
    is_verified BOOLEAN DEFAULT false, -- Doğrulandı mı?
    verified_at TIMESTAMPTZ, -- Doğrulama zamanı
    next_screen TEXT, -- Doğrulama sonrası gidilecek ekran
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- 8. İNDEKSLER (PERFORMANS İÇİN)
-- ============================================================================

-- Child profiles indeksleri
CREATE INDEX idx_child_profiles_user_id ON child_profiles(user_id);
CREATE INDEX idx_child_profiles_active ON child_profiles(user_id, is_active) WHERE is_active = true AND deleted_at IS NULL;
CREATE INDEX idx_child_profiles_deleted_at ON child_profiles(deleted_at) WHERE deleted_at IS NULL;
-- Partial unique index: Bir kullanıcının sadece 1 aktif profili olabilir
CREATE UNIQUE INDEX idx_unique_active_profile ON child_profiles(user_id) WHERE is_active = true AND deleted_at IS NULL;

-- Categories indeksleri
CREATE INDEX idx_categories_type ON categories(type) WHERE deleted_at IS NULL;
CREATE INDEX idx_categories_key ON categories(key) WHERE deleted_at IS NULL;
CREATE INDEX idx_categories_deleted_at ON categories(deleted_at) WHERE deleted_at IS NULL;

-- Contents indeksleri
CREATE INDEX idx_contents_category_id ON contents(category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_contents_type ON contents(type) WHERE deleted_at IS NULL;
CREATE INDEX idx_contents_display_order ON contents(category_id, display_order) WHERE deleted_at IS NULL;
CREATE INDEX idx_contents_slug ON contents(slug) WHERE deleted_at IS NULL AND slug IS NOT NULL;
CREATE INDEX idx_contents_deleted_at ON contents(deleted_at) WHERE deleted_at IS NULL;

-- Favorites indeksleri
CREATE INDEX idx_favorites_profile_id ON favorites(child_profile_id);
CREATE INDEX idx_favorites_category_id ON favorites(category_id);
CREATE INDEX idx_favorites_content_id ON favorites(content_id);

-- User settings indeksleri
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- Profile time limits indeksleri
CREATE INDEX idx_profile_time_limits_profile_id ON profile_time_limits(child_profile_id);

-- Daily usage logs indeksleri
CREATE INDEX idx_daily_usage_logs_profile_id ON daily_usage_logs(child_profile_id);
CREATE INDEX idx_daily_usage_logs_date ON daily_usage_logs(usage_date DESC);

-- User subscriptions indeksleri
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);
CREATE INDEX idx_user_subscriptions_end_date ON user_subscriptions(end_date) WHERE status = 'active';

-- Payment history indeksleri
CREATE INDEX idx_payment_history_subscription_id ON payment_history(subscription_id);
CREATE INDEX idx_payment_history_payment_date ON payment_history(payment_date DESC);

-- Feedbacks indeksleri
CREATE INDEX idx_feedbacks_user_id ON feedbacks(user_id);
CREATE INDEX idx_feedbacks_status ON feedbacks(status);

-- Parental verifications indeksleri
CREATE INDEX idx_parental_verifications_user_id ON parental_verifications(user_id);

-- ============================================================================
-- 9. TRIGGER'LAR (AUTO-UPDATE updated_at)
-- ============================================================================

-- Updated_at otomatik güncelleme fonksiyonu
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tüm tablolara trigger ekle
CREATE TRIGGER update_child_profiles_updated_at BEFORE UPDATE ON child_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contents_updated_at BEFORE UPDATE ON contents
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_profile_time_limits_updated_at BEFORE UPDATE ON profile_time_limits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_daily_usage_logs_updated_at BEFORE UPDATE ON daily_usage_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscription_plans_updated_at BEFORE UPDATE ON subscription_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_feedbacks_updated_at BEFORE UPDATE ON feedbacks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLİTİKALARI
-- ============================================================================

-- RLS'yi etkinleştir
ALTER TABLE child_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_time_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE parental_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

-- Child profiles: Kullanıcılar sadece kendi profillerini görebilir/düzenleyebilir
-- Soft delete kontrolü: deleted_at IS NULL
CREATE POLICY "Users can view own child profiles" ON child_profiles
    FOR SELECT USING (user_id = auth.uid() AND deleted_at IS NULL);

CREATE POLICY "Users can insert own child profiles" ON child_profiles
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own child profiles" ON child_profiles
    FOR UPDATE USING (user_id = auth.uid() AND deleted_at IS NULL);

-- NOT: DELETE politikası yok - soft delete kullanılıyor (deleted_at güncellenir)

-- Categories: Herkes okuyabilir, soft delete kontrolü ile
CREATE POLICY "Anyone can view categories" ON categories
    FOR SELECT USING (deleted_at IS NULL);

-- Contents: Herkes okuyabilir, soft delete kontrolü ile
-- İçerik silinmemiş olmalı VE bağlı olduğu kategori de silinmemiş olmalı
CREATE POLICY "Anyone can view contents" ON contents
    FOR SELECT USING (
        deleted_at IS NULL 
        AND category_id IN (
            SELECT id FROM categories WHERE deleted_at IS NULL
        )
    );

-- Favorites: Kullanıcılar sadece kendi favorilerini görebilir
CREATE POLICY "Users can view own favorites" ON favorites
    FOR SELECT USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

CREATE POLICY "Users can manage own favorites" ON favorites
    FOR ALL USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

-- User settings: Kullanıcılar sadece kendi ayarlarını görebilir
CREATE POLICY "Users can view own settings" ON user_settings
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can manage own settings" ON user_settings
    FOR ALL USING (user_id = auth.uid());

-- Profile time limits: Kullanıcılar sadece kendi profillerinin zaman sınırlarını görebilir
CREATE POLICY "Users can view own time limits" ON profile_time_limits
    FOR SELECT USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

CREATE POLICY "Users can manage own time limits" ON profile_time_limits
    FOR ALL USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

-- Daily usage logs: Kullanıcılar sadece kendi profillerinin kullanım loglarını görebilir
CREATE POLICY "Users can view own usage logs" ON daily_usage_logs
    FOR SELECT USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

-- Daily usage logs: Kullanıcılar kendi profilleri için log ekleyebilir
CREATE POLICY "Users can insert own usage logs" ON daily_usage_logs
    FOR INSERT WITH CHECK (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

-- Daily usage logs: Kullanıcılar kendi profilleri için log güncelleyebilir
CREATE POLICY "Users can update own usage logs" ON daily_usage_logs
    FOR UPDATE USING (
        child_profile_id IN (
            SELECT id FROM child_profiles WHERE user_id = auth.uid() AND deleted_at IS NULL
        )
    );

-- User subscriptions: Kullanıcılar sadece kendi aboneliklerini görebilir
CREATE POLICY "Users can view own subscriptions" ON user_subscriptions
    FOR SELECT USING (user_id = auth.uid());

-- Payment history: Kullanıcılar sadece kendi ödeme geçmişlerini görebilir
CREATE POLICY "Users can view own payment history" ON payment_history
    FOR SELECT USING (
        subscription_id IN (
            SELECT id FROM user_subscriptions WHERE user_id = auth.uid()
        )
    );

-- Feedbacks: Kullanıcılar sadece kendi geri bildirimlerini görebilir
CREATE POLICY "Users can view own feedbacks" ON feedbacks
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own feedbacks" ON feedbacks
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Parental verifications: Kullanıcılar sadece kendi doğrulamalarını görebilir
CREATE POLICY "Users can view own verifications" ON parental_verifications
    FOR SELECT USING (user_id = auth.uid());

-- Subscription plans: Herkes aktif planları okuyabilir
CREATE POLICY "Anyone can view subscription plans" ON subscription_plans
    FOR SELECT USING (is_active = true);

-- ============================================================================
-- 11. YORUM SATIRLARI (HANGİ EKRAN İÇİN HANGİ TABLO)
-- ============================================================================

COMMENT ON TABLE child_profiles IS 'Çocuk profilleri - ProfilesScreen, HomeScreen (aktif profil)';
COMMENT ON TABLE categories IS 'Kategoriler - CategoriesScreen, HomeScreen (kategori kartları)';
COMMENT ON TABLE contents IS 'İçerikler - BookReadingScreen, CardCategoriesDetailScreen, AwarenessCategoriesDetailScreen, BedtimeCategoriesDetailScreen, ColoringGameScreen, DrawTogetherScreen, MatchingCardsScreen vb. (Tüm içerikler tek tabloda)';
COMMENT ON TABLE favorites IS 'Favoriler - HomeScreen (En Sevilen Kartlar paneli)';
COMMENT ON TABLE user_settings IS 'Kullanıcı ayarları - SettingsScreen (bildirimler, ses, müzik, dil)';
COMMENT ON TABLE profile_time_limits IS 'Zaman sınırları - TimeLimitScreen (günlük limit, yasaklı saatler)';
COMMENT ON TABLE daily_usage_logs IS 'Günlük kullanım logları - TimeLimitScreen (bugünkü kullanım)';
COMMENT ON TABLE subscription_plans IS 'Abonelik planları - PlansScreen';
COMMENT ON TABLE user_subscriptions IS 'Kullanıcı abonelikleri - ManageSubscriptionScreen';
COMMENT ON TABLE payment_history IS 'Ödeme geçmişi - ManageSubscriptionScreen (fatura geçmişi)';
COMMENT ON TABLE feedbacks IS 'Geri bildirimler - FeedbackScreen';
COMMENT ON TABLE parental_verifications IS 'Ebeveyn doğrulama - ParentalVerificationScreen';

-- ============================================================================
-- ŞEMA TAMAMLANDI
-- ============================================================================
