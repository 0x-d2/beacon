# BeaconKit™ · Mac mini kurulumu

Katalog, evdeki Mac mini'de (`brain`) çalışan bir GitHub Actions runner'ı ile üretilir ve yalnız tailnet'e yayınlanır.
Aşağıdakiler bir kez yapılır. Referans: `docs/beaconkit.md` › Hosting.

**Kendi başına bir kurulum.** Beacon'ın mini'deki her parçası kendinedir: runner `~/actions-runner/beacon`'da,
görüntüler ve site `~/BeaconKit`'te, siteyi kendi Caddy süreci kendi yerel portundan sunar, tailnet'e kendi Tailscale
Serve portundan çıkar; portlar doluysa boş olanları kendisi seçer (5). Makinede başka projeler de çalışabilir;
Beacon onların dosyalarına, binary'lerine, yapılandırmasına ya da portlarına dayanmaz, onlar kaldırılsa etkilenmez.

**Runner public `0x-d2/beacon`'a asla kaydedilmez.** Public bir depoya herkes fork'layıp PR açabilir ve PR kendi iş
akışı dosyalarını çalıştırır: runner orada kayıtlı olsaydı biri `runs-on: beacon-kit` diyen bir dosyayla mini'de komut
çalıştırabilirdi. Runner ve iş akışı private **`0x-d2/beacon-kit-runner`** deposundadır; iş akışı public deponun bir
dalını ya da etiketini (varsayılan `custom`) çekip çalıştırır.

## 1. Runner

GitHub'da: **0x-d2/beacon-kit-runner › Settings › Actions › Runners › New self-hosted runner** (macOS, ARM64). Sayfanın
verdiği indirme ve `config.sh` komutlarını mini'de, **kendi klasöründe** çalıştırın:

```sh
mkdir -p ~/actions-runner/beacon && cd ~/actions-runner/beacon
# … sayfadaki curl + tar satırları …
./config.sh --url https://github.com/0x-d2/beacon-kit-runner --token <SAYFADAKİ-TOKEN> \
  --name brain-beacon-kit --labels beacon-kit --unattended
./svc.sh install
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/actions.runner.0x-d2-beacon-kit-runner.brain-beacon-kit.plist
```

- Etiket yalnız `beacon-kit`: private depodaki `kit.yml` bu etiketi ister, başka hiçbir workflow istemez.
- `./svc.sh start` SSH'tan GUI oturumunun dışına düşer; render'lar ekran istediği için `launchctl bootstrap gui/…`
  kullanın.
- Durum: `./svc.sh status`. Kaldırmak: `./svc.sh uninstall && ./config.sh remove --token <TOKEN>`.
- `0x-d2/beacon-kit-runner` private kalmalı ve işbirlikçi eklenmemeli. `kit.yml` yalnız elle ve yalnız depo sahibi
  tetiklediğinde çalışır; public depodan yalnız bir dal ya da etiket çeker (onları yalnız depo sahibi gönderebilir), PR
  başlığı ya da çıplak commit kabul etmez.

## 2. Node ve gh

İş akışı Node'u kendisi kurar (`actions/setup-node`, Node 25). `gh` Homebrew'den (`/opt/homebrew/bin`) gelir; revize
notlarını okumak için workflow kendi token'ını verir, mini'de ayrıca `gh auth login` gerekmez.

## 3. Ekran: HiDPI ve uyku

Render'lar mini'nin ekranında çekilir; renderer @1x bir ekranda çekmez (site @2x görüntü gösterir).

- **HiDPI:** mini'ye bir HDMI dummy plug (4K) takın, ya da BetterDisplay ile HiDPI sanal bir ekran açın. Kontrol:
  Sistem Ayarları › Ekranlar'da çözünürlük "… (HiDPI)" ya da Retina ölçekli olmalı.
- **Otomatik giriş açık, FileVault kapalı:** runner GUI oturumunda çalışır; yeniden başlatmadan sonra oturum
  kendiliğinden açılmalı.
- **Ekran uykusu:** `kit.sh` çekim süresince `caffeinate -d` tutar; yine de Enerji ayarlarında ekran uykusunu kapatmak
  iyi olur. Ekran kilitliyken çekim yapılmaz.

## 4. Ekran Kaydı izni (isteğe bağlı, önerilir)

İzin olmadan da render'lar çekilir, ama malzemeler (panelin camı, HUD) arkalarındaki zemini bulanıklaştırmaz, düz
çıkar; site bunu "malzeme düz" diye işaretler. Gerçek görünüm için bir kez:

1. Workflow'u bir kez `scope=components` ile çalıştırın: `~/BeaconKit/BeaconKit Renderer.app` oluşur.
2. Mini'ye Ekran Paylaşımı ile bağlanın: **Sistem Ayarları › Gizlilik ve Güvenlik › Ekran ve Sistem Sesi Kaydı** › **+**
   › `~/BeaconKit/BeaconKit Renderer.app`.
3. İzin, renderer aynı kimlikle imzalandıkça (derleme her seferinde aynı yerel kimliği kullanır) kalır. macOS ara ara
   yeniden sorabilir: renderer beklemez, o çekimde malzemeler düz çıkar.

## 5. Sunucu: Caddy ve Tailscale Serve

Site tek sayfalık bir uygulama (bilinmeyen bir yol `index.html`'e düşmeli), bu yüzden dosyaları Caddy sunar; tailnet'e
Tailscale Serve çıkarır. İkisini de `docs/scripts/kit-serve.sh` kurar ve iş akışı her yayından sonra onu çalıştırır.
Elle yapılacak olan yalnız araçlar:

```sh
brew install caddy     # jq macOS'ta yoksa: brew install jq
tailscale status       # mini tailnet'te, oturum açık olmalı
```

- **Portları kendisi seçer.** Caddy yerelde `127.0.0.1:8789`'dan, Serve tailnet'te `8445`'ten başlar. Bir port başka
  bir sunucunun ya da başka bir Serve kaydının elindeyse sıradaki boş porta geçer (8789–8888, 8445–8544). Seçtiği
  portları `~/BeaconKit/serve.env`'de tutar ve sonraki yayınlarda, hâlâ Beacon'ınsa korur. Başkasının dinlediği porta
  ya da Serve kaydına hiç dokunmaz: yalnız kendi kaydettiği portu kendisininki sayar.
- **Kendi Caddy'si:** `~/BeaconKit/Caddyfile`, LaunchAgent `co.ikili.beaconkit.caddy`, günlük `~/BeaconKit/caddy.log`.
  Yönetim API'si kapalı (`admin off`), böylece makinedeki başka bir Caddy'nin `localhost:2019`'uyla da çakışmaz.
- **Elle:** bir checkout'ta `docs/scripts/kit-serve.sh` kurar ya da onarır ve adresi yazar; `--dry-run` yalnız hangi
  portları kullanacağını söyler. Durdurmak: `launchctl bootout gui/$(id -u)/co.ikili.beaconkit.caddy` ve
  `tailscale serve --https=<tailnet portu> off`.

## 6. Adres

Her yayın adresi (`https://brain.<tailnet>.ts.net:<port>`) çalıştırmanın özetine yazar. Adres ya da yerel port
değişince `0x-d2/beacon-kit-runner`'daki **"BeaconKit adresi"** issue'suna yeni bir yorum düşer ve GitHub bunu size
bildirir. Adres tailnet'in adını taşıdığı için yalnız private depoya yazılır, public depoya asla. Mini'yi tailnet'te
başka kullanıcılarla paylaşıyor ve ACL'de port kısıtlıyorsanız, port değişince ACL'i de güncelleyin.

## 7. İlk çalıştırma

```sh
gh workflow run kit.yml -R 0x-d2/beacon-kit-runner -f ref=custom -f scope=all
gh run watch -R 0x-d2/beacon-kit-runner
```

`ref` public deponun bir dalı ya da etiketidir; bir özellik dalını birleşmeden önce çekmek için onun adını verin
(`-f ref=0x-d2/watchos-companion-app-stats`). İlk yayın Caddy'yi ve Serve kaydını da kurar; adres çalıştırmanın
özetinde ve "BeaconKit adresi" issue'sunda.
