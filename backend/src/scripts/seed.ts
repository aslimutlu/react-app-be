import { getSupabaseClient } from '../lib/supabase';

const supabase = getSupabaseClient();

interface Category {
  type: 'card' | 'story' | 'play' | 'awareness' | 'bedtime';
  key: string;
  name: string;
  description?: string;
  image_url?: string;
  background_image_url?: string;
  background_color?: string;
  show_item_image?: boolean;
  text_position?: string;
  text_orientation?: string;
  text_size?: string;
  display_order?: number;
}

interface Content {
  category_id: string;
  type: 'story' | 'card' | 'game-coloring' | 'game-matching' | 'game-counting' | 'game-drawing' | 'game-find-shape' | 'game-what-hear' | 'awareness' | 'bedtime';
  title: string;
  slug?: string;
  image_url?: string;
  background_image_url?: string;
  audio_file_url?: string;
  text_content?: string;
  capture_text?: string;
  display_order?: number;
  metadata?: Record<string, unknown>;
}

const categories: Category[] = [
  {
    type: 'bedtime',
    key: 'uyku-masallari',
    name: 'Uyku Masalları',
    description: 'Uyumadan önce dinlenecek güzel masallar',
    image_url: 'https://placehold.co/600x400',
    background_color: 'bg-blue-400',
    show_item_image: true,
    text_position: 'bottom',
    text_orientation: 'horizontal',
    text_size: 'medium',
    display_order: 1,
  },
  {
    type: 'card',
    key: 'meslekler',
    name: 'Meslekleri Tanıyalım',
    description: 'Farklı meslekleri öğrenelim',
    image_url: 'https://placehold.co/600x400',
    background_color: 'bg-green-400',
    show_item_image: true,
    text_position: 'bottom',
    text_orientation: 'horizontal',
    text_size: 'medium',
    display_order: 2,
  },
  {
    type: 'play',
    key: 'matematik',
    name: 'Eğlenceli Matematik',
    description: 'Matematik oyunları ve aktiviteler',
    image_url: 'https://placehold.co/600x400',
    background_color: 'bg-purple-400',
    show_item_image: true,
    text_position: 'center',
    text_orientation: 'horizontal',
    text_size: 'medium',
    display_order: 3,
  },
];

const main = async () => {
  try {
    console.log('🌱 Seed işlemi başlatılıyor...');

    // 1. Temizlik
    console.log('🧹 Veritabanı temizleniyor...');
    
    // Önce foreign key bağımlılıkları nedeniyle sırayla sil
    // Soft delete kullanıldığı için deleted_at IS NULL olanları silmek yerine
    // Tüm kayıtları siliyoruz (test için)
    const { error: deleteFavoritesError } = await supabase
      .from('favorites')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (deleteFavoritesError) {
      throw new Error(`favorites silme hatası: ${deleteFavoritesError.message}`);
    }

    const { error: deleteContentsError } = await supabase
      .from('contents')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (deleteContentsError) {
      throw new Error(`contents silme hatası: ${deleteContentsError.message}`);
    }

    const { error: deleteCategoriesError } = await supabase
      .from('categories')
      .delete()
      .neq('id', '00000000-0000-0000-0000-000000000000');

    if (deleteCategoriesError) {
      throw new Error(`categories silme hatası: ${deleteCategoriesError.message}`);
    }

    console.log('✅ Temizlik tamamlandı');

    // 2. Kategori Ekleme
    console.log('📁 Kategoriler ekleniyor...');
    
    const insertedCategories = await Promise.all(
      categories.map(async (category) => {
        const { data, error } = await supabase
          .from('categories')
          .insert(category)
          .select()
          .single();

        if (error) {
          throw new Error(`Kategori ekleme hatası (${category.name}): ${error.message}`);
        }

        return data;
      })
    );

    console.log(`✅ ${insertedCategories.length} kategori eklendi`);

    // 3. İçerik Ekleme
    console.log('📚 İçerikler ekleniyor...');

    const uykuMasallariCategory = insertedCategories.find((c) => c.key === 'uyku-masallari');
    const mesleklerCategory = insertedCategories.find((c) => c.key === 'meslekler');
    const matematikCategory = insertedCategories.find((c) => c.key === 'matematik');

    if (!uykuMasallariCategory || !mesleklerCategory || !matematikCategory) {
      throw new Error('Kategoriler bulunamadı');
    }

    const contents: Content[] = [
      // Uyku Masalları - 2 hikaye
      {
        category_id: uykuMasallariCategory.id,
        type: 'story',
        title: 'Ayıcık ve Yıldızlar',
        slug: 'ayicik-ve-yildizlar',
        image_url: 'https://placehold.co/600x400',
        background_image_url: 'https://placehold.co/1200x800',
        audio_file_url: 'https://placehold.co/600x400',
        text_content: 'Bir varmış bir yokmuş, evvel zaman içinde...',
        capture_text: 'Ayıcık ve Yıldızlar',
        display_order: 1,
        metadata: {
          page_count: 10,
          duration_minutes: 5,
        },
      },
      {
        category_id: uykuMasallariCategory.id,
        type: 'story',
        title: 'Büyülü Orman',
        slug: 'buyulu-orman',
        image_url: 'https://placehold.co/600x400',
        background_image_url: 'https://placehold.co/1200x800',
        audio_file_url: 'https://placehold.co/600x400',
        text_content: 'Büyülü ormanda yaşayan sevimli hayvanların hikayesi...',
        capture_text: 'Büyülü Orman',
        display_order: 2,
        metadata: {
          page_count: 12,
          duration_minutes: 6,
        },
      },
      // Meslekler - İtfaiyeci ve Doktor (card tipi)
      {
        category_id: mesleklerCategory.id,
        type: 'card',
        title: 'İtfaiyeci',
        slug: 'itfaiyeci',
        image_url: 'https://placehold.co/600x400',
        text_content: 'İtfaiyeciler yangınları söndürür ve insanları kurtarır.',
        capture_text: 'İtfaiyeci',
        display_order: 1,
        metadata: {
          description: 'İtfaiyecilerin ne yaptığını öğrenelim',
        },
      },
      {
        category_id: mesleklerCategory.id,
        type: 'card',
        title: 'Doktor',
        slug: 'doktor',
        image_url: 'https://placehold.co/600x400',
        text_content: 'Doktorlar hastaları iyileştirir ve sağlığımızı korur.',
        capture_text: 'Doktor',
        display_order: 2,
        metadata: {
          description: 'Doktorların ne yaptığını öğrenelim',
        },
      },
      // Matematik - Sayma oyunu
      {
        category_id: matematikCategory.id,
        type: 'game-counting',
        title: 'Sayıları Sayalım',
        slug: 'sayilari-sayalim',
        image_url: 'https://placehold.co/600x400',
        display_order: 1,
        metadata: {
          difficulty: 'easy',
          instructions: 'Ekrandaki nesneleri sayın',
          svg_id: 'counting-template-1',
        },
      },
    ];

    const { data: insertedContents, error: insertContentsError } = await supabase
      .from('contents')
      .insert(contents)
      .select();

    if (insertContentsError) {
      throw new Error(`İçerik ekleme hatası: ${insertContentsError.message}`);
    }

    console.log(`✅ ${insertedContents?.length || 0} içerik eklendi`);

    // 4. Test Kullanıcısı Oluşturma
    console.log('👤 Test kullanıcısı oluşturuluyor...');

    // Önce mevcut kullanıcıyı kontrol et
    const { data: usersList, error: listError } = await supabase.auth.admin.listUsers();
    
    if (listError) {
      throw new Error(`Kullanıcı listeleme hatası: ${listError.message}`);
    }

    const existingUser = usersList?.users.find((user) => user.email === 'test@demo.com');

    let userId: string;

    if (existingUser) {
      console.log('⚠️  Test kullanıcısı zaten mevcut, güncelleniyor...');
      userId = existingUser.id;
      
      // Kullanıcıyı güncelle
      const { error: updateError } = await supabase.auth.admin.updateUserById(userId, {
        password: 'password123',
      });

      if (updateError) {
        throw new Error(`Kullanıcı güncelleme hatası: ${updateError.message}`);
      }
    } else {
      // Yeni kullanıcı oluştur
      const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
        email: 'test@demo.com',
        password: 'password123',
        email_confirm: true,
      });

      if (createError) {
        throw new Error(`Kullanıcı oluşturma hatası: ${createError.message}`);
      }

      if (!newUser.user) {
        throw new Error('Kullanıcı oluşturuldu ancak user bilgisi alınamadı');
      }

      userId = newUser.user.id;
      console.log('✅ Test kullanıcısı oluşturuldu');
    }

    // 5. Test Child Profile Oluşturma
    console.log('👶 Test çocuk profili oluşturuluyor...');

    // Mevcut child profile'ı kontrol et
    const { data: existingProfiles } = await supabase
      .from('child_profiles')
      .select('id')
      .eq('user_id', userId)
      .is('deleted_at', null)
      .limit(1);

    if (existingProfiles && existingProfiles.length > 0) {
      console.log('⚠️  Test çocuk profili zaten mevcut');
    } else {
      // Yeni child profile oluştur
      const { error: profileError } = await supabase
        .from('child_profiles')
        .insert({
          user_id: userId,
          name: 'Test Çocuk',
          avatar_type: 'boy',
          background_color: 'bg-blue-100',
          is_active: true,
        });

      if (profileError) {
        throw new Error(`Çocuk profili oluşturma hatası: ${profileError.message}`);
      }

      console.log('✅ Test çocuk profili oluşturuldu');
    }

    console.log('\n🎉 Seed tamamlandı! 🚀');
    console.log('\n📋 Özet:');
    console.log(`   - ${insertedCategories.length} kategori eklendi`);
    console.log(`   - ${insertedContents?.length || 0} içerik eklendi`);
    console.log(`   - Test kullanıcısı: test@demo.com / password123`);
    console.log(`   - Kullanıcı ID: ${userId}`);
  } catch (error) {
    console.error('❌ Seed hatası:', error);
    process.exit(1);
  }
};

// Script'i çalıştır
main();
