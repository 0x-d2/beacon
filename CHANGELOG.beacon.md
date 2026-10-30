# Beacon · değişiklik günlüğü

Beacon'da fark edilen her değişiklik: iPhone ve Apple Watch uygulamaları, Mac'teki **iPhone'dan izle** ve BeaconKit™
kataloğu. En yeni gün ve her günün en yeni satırı üstte. İngilizcesi `CHANGELOG.beacon.en.md`. Vorssaint'in kendi
günlüğü `CHANGELOG.md`'dir; Beacon oraya yazılmaz.

## 2026-10-31

- **Geliştirme:** Ajanlar her işi `custom` dalından açıp PR'ını `custom`'a gönderiyor; Conductor çalışma alanına başka
  bir hedef dal gösterse de.

## 2026-10-30

- **BeaconKit:** Katalog artık ayrı, private bir depodan (`0x-d2/beacon-kit-runner` › Actions › BeaconKit™) üretiliyor;
  evdeki Mac mini'nin runner'ı public depoya hiç bağlanmıyor, böylece kimsenin PR'ı Mac'e ulaşamıyor.
- **Geliştirme:** Beacon artık GitHub'da kendi `custom` dalında toplanıyor, `main` Vorssaint'in birebir aynası;
  Vorssaint'in yenilikleri her sabah `custom`'a PR olarak geliyor, workflow değiştiren güncellemeler önce sana
  soruluyor.
- **Geliştirme:** Ajanlar için çalışma kuralları ve proje haritası: `AGENTS.md` ve `ref/` belgeleri; bu günlük ve
  Claude Code iş bitirirken günlüğe yazılmamış bir değişiklik varsa bunu soran kontrol.
- **iPhone:** Bağlanırken yanıp sönen durum noktası artık yerinden kayıp başka yerde kalmıyor.
- **iPhone:** Ayarlar › Gizlilik, ölçümlerin Apple Watch'a da iletildiğini ve Mac anahtarlarının saate gitmediğini
  söylüyor.
- **Apple Watch:** Kadrana Mac komplikasyonu eklenebiliyor: CPU, bellek, GPU ya da sıcaklık; halka, köşe, satır ya da
  dikdörtgen. Saatin en son okuduğu değeri saatiyle gösteriyor, 10 dakika sonra soluklaşıyor; dokununca o Mac açılıyor.
- **Apple Watch:** Beacon artık Apple Watch'ta: Mac'in sekiz ölçümü tek listede, her biri iPhone'daki satırların
  aynısıyla bir sayfa açıyor. Saat Mac'e iPhone üzerinden ulaşıyor; iPhone yakında olmalı, Beacon'ın açık olması
  gerekmiyor.
- **BeaconKit:** Katalog Beacon iPhone uygulamasını da gösteriyor: bileşenleri, ekranları ve renkleri (her rengin
  Mac'teki karşılığıyla), Türkçe ve İngilizce, koyu ve açık.
- **Mac:** Eşleşmiş telefonlar anahtar zincirinden doğru okunuyor; önceden liste hep boş geliyor ve iPhone'dan izle
  dinlemeye hiç başlamıyordu.
- **iPhone:** Uygulama dışından (Kamera'dan, bir web sayfasından) açılan eşleştirme bağlantısı kaydedilmeden önce Mac'in
  adını ve adreslerini gösterip onay istiyor. Aynı ad ve adrese sahip başka bir Mac artık silinmiyor.
- **iPhone:** Beacon, Mac'i izleyen iPhone uygulaması: QR koduyla eşleştirme, gösterge paneli, her ölçüm için son 4
  dakikanın grafiği ve ayrıntıları, evden uzakta Tailscale ile bağlantı, Mac olmadan denemek için örnek Mac. Türkçe ve
  İngilizce.
- **Mac:** Ayarlar › Monitör › iPhone'dan izle: telefon QR koduyla eşleştiriliyor, Mac ölçümlerini yalnız eşleşmiş
  telefonlara, her birinin kendi anahtarıyla şifreli gönderiyor ve yalnız bir telefon izlerken ölçüyor. Varsayılan
  kapalı.
- **BeaconKit:** İşlem satırı örneğindeki ondalıklar görüntünün diliyle yazılıyor (Türkçede virgül).
- **BeaconKit:** Katalog uygulamanın kendi piksellerini gösteriyor: her bileşen ve bazı yüzeyler Türkçe ve İngilizce,
  koyu ve açık temada fotoğraflanıyor.
- **BeaconKit:** BeaconKit™ katalog sitesi: uygulamanın renkleri, bileşenleri, yüzeyleri ve satır içi değerleri, her
  biri onu yazan satırla; "Neyi nereden değiştiririm" rehberi; "Not bırak" ile revizyon notu.
