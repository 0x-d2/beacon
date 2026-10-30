# Beacon · iPhone ve Apple Watch uygulaması

Mac'in sistem ölçümlerini (CPU, GPU, bellek, sıcaklıklar, ağ, güç, diskler, fanlar) iPhone'da ve Apple Watch'ta canlı
gösterir. Mac tarafı Vorssaint'in **Ayarlar › Monitör › iPhone'dan izle** kartıdır (`docs/remote-monitor.md`). İkisi
aynı protokol dosyasını derler: `Sources/Vorssaint/Services/RemoteMonitor/RemoteMonitorProtocol.swift`.

## Telefonuna kurmak (Xcode'dan)

Gerekenler: Xcode 27, iOS 27 bir iPhone, Apple Developer hesabın (ücretsiz hesap da olur, uygulama 7 gün sonra yeniden
kurulmak ister), XcodeGen (`brew install xcodegen`).

```sh
cd iOS
cp Config/Local.xcconfig.example Config/Local.xcconfig   # bir kez: içine kendi DEVELOPMENT_TEAM'ini yaz
xcodegen generate                                          # Beacon.xcodeproj'u üretir (repo'ya girmez)
open Beacon.xcodeproj
```

Xcode'da hedef olarak iPhone'unu seç (kabloyla ya da aynı ağda Wi‑Fi ile), **Run**. İlk kurulumda iPhone'da
**Ayarlar › Genel › VPN ve Cihaz Yönetimi**'nden geliştiriciye güvenmen gerekebilir. Team kimliğin:
`security find-identity -v -p codesigning` çıktısında adının yanındaki parantez içindeki 10 karakter.

## Eşleştirmek

1. Mac'te Vorssaint › **Ayarlar › Monitör › iPhone'dan izle**'yi aç, **Telefon ekle**'ye bas: bir QR kodu çıkar
   (10 dakika geçerli).
2. iPhone'da Beacon › **Mac ekle** ile kodu okut. iPhone'un kendi Kamera uygulaması da olur: kod bir `beacon://`
   bağlantısıdır ve Beacon'ı açar. Kamera yoksa Mac'te **Bağlantıyı kopyala**, iPhone'a yapıştır (Evrensel Pano).
3. İlk bağlantıda iOS yerel ağ izni sorar: izin ver.

Evden uzaktayken: Mac'te ve iPhone'da Tailscale açıksa Beacon, kodun taşıdığı ikinci adresten (Mac'in Tailscale adresi
ya da kartta yazdığın MagicDNS adı) bağlanır. Her telefonun kendi anahtarı vardır; Mac'te bir telefonu kaldırınca o
telefon bağlanamaz.

## Apple Watch

Saat uygulaması iPhone uygulamasının içinde gelir: iPhone'a Beacon kurulunca saate de kurulur (otomatik kurulum
kapalıysa iPhone'daki **Watch** uygulamasından eklenir). Ayrı bir eşleştirme yok: saat, iPhone'da eşleşmiş Mac'leri
görür; tek Mac varsa doğrudan onu açar.

- **Saat Mac'e kendi bağlanmaz.** watchOS, Mac'in anahtarla korunan bağlantısının tek yolu olan Network framework'ü
  yalnız ses ve arama uygulamalarına açar (Apple TN3135; simülatör bu kısıtı uygulamaz). Ölçümleri iPhone okur ve
  WatchConnectivity ile saate iletir. Saat bir Mac'i gösterdiği sürece 5 sn'de bir iPhone'a haber verir; bu,
  Beacon'ı iPhone'da arka planda uyandırır. Saat 15 sn susunca iPhone Mac'i izlemeyi bırakır. iPhone saatin yakınında
  (Bluetooth ya da aynı Wi‑Fi) olmalı; anahtarlar iPhone'dan çıkmaz, saat Mac'leri yalnız adı ve kimliğiyle bilir.
- **Ekranlar:** Mac'in sekiz ölçümü tek listede, her biri bir sayfa açar; sayfalar iPhone'daki satırların aynısını
  gösterir (`Features/Detail/MetricRows.swift`, iki uygulama da derler).
- **Komplikasyon:** kadranda CPU, bellek, GPU ya da sıcaklık (halka, köşe, satır ya da dikdörtgen). Saat Mac'i yalnız
  uygulama açıkken okuyabildiği için komplikasyon en son okumayı ve saatini gösterir, 10 dakika sonra soluklaşır;
  dokununca uygulama o Mac'le açılır. Uygulama ile komplikasyon bunu `group.co.ikili.beacon` App Group'unda paylaşır,
  ikisi de bu yetkiyle imzalanır: ücretli hesapta Xcode grubu kendisi kaydeder. Kişisel (ücretsiz) takım App Groups'u
  kabul etmezse `project.yml`'de `BeaconWatch` ile `BeaconWatchWidgets`'ın `entitlements` bloğunu kaldırmak yeter;
  uygulama çalışır, komplikasyon boş kalır.
- **Simülatörde:** eşli bir iPhone + Apple Watch simülatör çifti gerekir (Xcode › Window › Devices and Simulators ya da
  `xcrun simctl pair`). `Beacon` şeması saat uygulamasını da derleyip iPhone uygulamasının içine koyar; saate ayrıca
  `BeaconWatch` şemasıyla ya da `xcrun simctl install <saat> …/Debug-watchsimulator/BeaconWatch.app` ile kurulur.
  Saat uygulaması da `-demo 1` ve `-screen dashboard|cpu|memory|…` alır.

## Mac olmadan denemek

- Uygulamada **Örnek veriyle dene**: demo Mac, hiçbir ağa bağlanmaz.
- Simülatörde açılış argümanları: `-demo 1` (eşleşmiş Mac'leri yüklemez), `-screen dashboard` (ya da `cpu`, `memory`,
  `network`, `power`, `disk`, `temperature`, `gpu`, `fans`: o ekranı demo Mac'le açar), `-pair <beacon://… bağlantısı>`.
- **Ayarlar › Tasarım kataloğu**: uygulamanın her bileşeni her hâliyle (BeaconKit™'in iOS tarafı).

## Yapı

| | |
|---|---|
| `Beacon/Connection/MacSession.swift` | Bir Mac'le bağlantı: TLS 1.2 PSK + WebSocket, önce `.local` adı sonra uzak adres, kopunca 1–30 sn artan bekleme, ekran açıkken abonelik |
| `Beacon/Connection/PairedMac.swift` | Eşleşmiş Mac'ler, her biri telefonun anahtar zincirinde (iCloud'a gitmez) |
| `Beacon/Stores/AppModel.swift` | Mac'ler, oturumlar, eşleştirme, gezinme |
| `Beacon/Features/` | Mac listesi, gösterge paneli, metrik detayları (Swift Charts), eşleştirme (VisionKit QR), ayarlar |
| `Beacon/DesignSystem/` | Token'lar (`BeaconColor`: renkler Mac'teki `PanelMetricColor` anlamlarıyla aynı; `BeaconType`, `BeaconMetrics`, `BeaconMotion`) ve bileşenler; her bileşen bir `KitSpecimen` tanımlar, `#Preview`'lar ve katalog onu çizer |
| `Beacon/Connection/WatchLink.swift`, `WatchRelay.swift` | iPhone ile saatin mesajları; saat bir Mac'i gösterdikçe iPhone'un onu saat adına okuyup iletmesi |
| `Beacon/Stores/Readings.swift` | İki uygulamanın da okuduğu: ölçüm türleri (`MetricKind`), grafik geçmişi, bir okumanın başlığı |
| `Beacon/Resources/Localizable.xcstrings` | İngilizce ve Türkçe metinler (iPhone, saat ve komplikasyon) |
| `BeaconWatch/` | Saat uygulaması: `WatchModel` (Mac'ler, iPhone'la konuşma, kalp atışı), liste, gösterge paneli, ölçüm sayfası, watchOS renkleri |
| `BeaconWatchWidgets/` | Komplikasyonlar (WidgetKit); son okumayı `BeaconWatch/Shared/LastReading.swift`'ten okur |
| `BeaconTests/` | Swift Testing: eşleştirme bağlantısı, mesajlar, geçmiş, biçimler, saatle konuşma |

```sh
xcodebuild -project Beacon.xcodeproj -scheme Beacon -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Simülatörde Keychain için uygulama imzalı derlenmeli (Xcode'un "Sign to Run Locally"si yeter; `CODE_SIGNING_ALLOWED=NO`
ile derlenen bir kopya eşleşmeyi kaydedemez).
