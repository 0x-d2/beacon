# Beacon · iPhone uygulaması

Mac'in sistem ölçümlerini (CPU, GPU, bellek, sıcaklıklar, ağ, güç, diskler, fanlar) iPhone'da canlı gösterir. Mac
tarafı Vorssaint'in **Ayarlar › Monitör › iPhone'dan izle** kartıdır (`docs/remote-monitor.md`). İkisi aynı protokol
dosyasını derler: `Sources/Vorssaint/Services/RemoteMonitor/RemoteMonitorProtocol.swift`.

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
| `Beacon/Resources/Localizable.xcstrings` | İngilizce ve Türkçe metinler |
| `BeaconTests/` | Swift Testing: eşleştirme bağlantısı, mesajlar, geçmiş, biçimler |

```sh
xcodebuild -project Beacon.xcodeproj -scheme Beacon -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test
```

Simülatörde Keychain için uygulama imzalı derlenmeli (Xcode'un "Sign to Run Locally"si yeter; `CODE_SIGNING_ALLOWED=NO`
ile derlenen bir kopya eşleşmeyi kaydedemez).
