# The Seven Sleepers — Control Panel

Bu sürüm, mevcut JARVIS HTML uygulamasının görsel yapısını koruyup:
- Uyku modülünü tamamen kaldırır.
- Supabase Auth ile 7 kullanıcı girişini kullanır.
- Kişisel gelişim kayıtlarını merkezi PostgreSQL veritabanında tutar.
- Topluluk sayfasında haftalık sıralama + grafik + aktivite akışı gösterir.
- `Not:` alanını topluluk akışında gösterir; tıklayınca tam özet/not modal içinde açılır.
- Ortak görevlerde miktar/birim sistemi kullanır: örn. `100 Bab`, `50 Sayfa`, `300 Tekrar`.
- Kişisel notları topluluktan ayrı tutar.

## 1. Supabase
1. Supabase'te yeni proje oluştur.
2. SQL Editor'a `schema.sql` içeriğini yapıştırıp çalıştır.
3. Authentication > Providers > Email aktif olsun.
4. Email confirmation kullanmayacaksan kapatabilirsin.
5. Authentication > Users > Add user ile 7 kullanıcı oluştur:
   - said@seven-sleepers.local
   - ahmet@seven-sleepers.local
   - emre@seven-sleepers.local
   - furkan@seven-sleepers.local
   - talha@seven-sleepers.local
   - yasir@seven-sleepers.local
   - ihsan@seven-sleepers.local

Kullanıcı şifrelerini Supabase Dashboard'dan belirle. Örneğin kullanıcının istediği başlangıç düzeninde `said123`, `ahmet123` vb. olabilir; ancak gerçek kullanımda daha güçlü şifre tercih edilir.

Kullanıcı oluşturulunca trigger otomatik olarak `profiles` satırı oluşturur.

## 2. index.html
`index.html` içindeki:
```js
const SUPABASE_URL='YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY='YOUR_SUPABASE_ANON_KEY';
```
alanlarını Supabase Project Settings > API bölümündeki Project URL ve anon/public key ile değiştir.

Anon key frontend'de kullanılabilir; Service Role Key'i ASLA index.html içine koyma.

## 3. Vercel
Bu klasörü GitHub'a gönder:
```bash
git init
git add .
git commit -m "initial seven sleepers control panel"
git branch -M main
git remote add origin REPO_URL
git push -u origin main
```
Sonra Vercel'de repository'yi import et. Build command gerekmez; root directory içindeki `index.html` doğrudan servis edilebilir.

## Veri modeli
- profiles
- growth_records
- notes
- personal_tasks
- shared_tasks
- shared_task_members

Toplulukta örnek görünüm:
Said
📚 Risale-i Nur - 3. Lem'a
Not: ...

Kayda tıklanınca yazılmış özet/notun tamamı açılır.

## Sonraki geliştirmeler
- Profil fotoğrafı
- Haftalık/aylık filtre
- Daha gelişmiş topluluk istatistikleri
- Ortak görevlerde kişi bazlı katkı tablosu
- Admin rolü
- PWA / telefona ana ekran uygulaması
