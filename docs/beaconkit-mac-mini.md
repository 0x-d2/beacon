# BeaconKit™ · Mac mini kurulumu

Katalog, evdeki Mac mini'de (`brain`) çalışan bir GitHub Actions runner'ı ile üretilir ve yalnız tailnet'e yayınlanır.
Ata-Online'ın `ata-kit` runner'ı aynı makinede durur; Beacon için ikinci, ayrı bir runner kurulur. Aşağıdakiler bir
kez yapılır. Referans: `docs/beaconkit.md` › Hosting.

**Runner public `0x-d2/beacon`'a asla kaydedilmez.** Public bir depoya herkes fork'layıp PR açabilir ve PR kendi iş
akışı dosyalarını çalıştırır: runner orada kayıtlı olsaydı biri `runs-on: beacon-kit` diyen bir dosyayla mini'de komut
çalıştırabilirdi. Runner ve iş akışı private **`0x-d2/beacon-kit-runner`** deposundadır; iş akışı public deponun bir
dalını ya da etiketini (varsayılan `custom`) çekip çalıştırır.

## 1. Runner

GitHub'da: **0x-d2/beacon-kit-runner › Settings › Actions › Runners › New self-hosted runner** (macOS, ARM64). Sayfanın
verdiği indirme ve `config.sh` komutlarını mini'de, **ayrı bir klasörde** çalıştırın:

```sh
mkdir -p ~/actions-runner/beacon && cd ~/actions-runner/beacon
# … sayfadaki curl + tar satırları …
./config.sh --url https://github.com/0x-d2/beacon-kit-runner --token <SAYFADAKİ-TOKEN> \
  --name brain-beacon-kit --labels beacon-kit --unattended
./svc.sh install
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/actions.runner.0x-d2-beacon-kit-runner.brain-beacon-kit.plist
```

- Etiket yalnız `beacon-kit`: private depodaki `kit.yml` bu etiketi ister, başka hiçbir workflow istemez.
- `./svc.sh start` SSH'tan GUI oturumunun dışına düşer; `launchctl bootstrap gui/…` kullanın (Ata'dakiyle aynı).
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
- **Otomatik giriş açık, FileVault kapalı:** runner GUI oturumunda çalışır; yeniden başlatmadan sonra oturum kendiliğinden
  açılmalı. (Ata için zaten böyle.)
- **Ekran uykusu:** `kit.sh` çekim süresince `caffeinate -d` tutar; yine de Enerji ayarlarında ekran uykusunu kapatmak iyi
  olur. Ekran kilitliyken çekim yapılmaz.

## 4. Ekran Kaydı izni (isteğe bağlı, önerilir)

İzin olmadan da render'lar çekilir, ama malzemeler (panelin camı, HUD) arkalarındaki zemini bulanıklaştırmaz, düz çıkar;
site bunu "malzeme düz" diye işaretler. Gerçek görünüm için bir kez:

1. Workflow'u bir kez `scope=components` ile çalıştırın: `~/BeaconKit/BeaconKit Renderer.app` oluşur.
2. Mini'ye Ekran Paylaşımı ile bağlanın: **Sistem Ayarları › Gizlilik ve Güvenlik › Ekran ve Sistem Sesi Kaydı** › **+** ›
   `~/BeaconKit/BeaconKit Renderer.app`.
3. İzin, renderer aynı kimlikle imzalandıkça (derleme her seferinde aynı yerel kimliği kullanır) kalır. macOS ara ara yeniden
   sorabilir: renderer beklemez, o çekimde malzemeler düz çıkar.

## 5. Caddy

Ata için çalışan Caddy'ye bir blok ekleyin (`~/AtaKit/Caddyfile`), ya da Beacon'a ayrı bir Caddyfile açın:

```caddyfile
http://127.0.0.1:8789 {
	root * {$HOME}/BeaconKit/site/current
	encode gzip
	header Cache-Control no-cache
	try_files {path} /index.html
	file_server
}
```

Sonra Caddy'yi yeniden yükleyin (`~/AtaKit/bin/caddy reload --config ~/AtaKit/Caddyfile`).

## 6. Tailscale

```sh
tailscale serve --bg --https=8445 http://127.0.0.1:8789
tailscale serve status
```

8443 ve 8444 Ata'nın; onlara dokunmayın. Site: `https://brain.<tailnet>.ts.net:8445`. Paylaşılan kullanıcılara
yalnız bu portu açmak için Tailscale ACL'ine Ata'daki gibi `tcp:8445` ekleyin.

## 7. İlk çalıştırma

```sh
gh workflow run kit.yml -R 0x-d2/beacon-kit-runner -f ref=custom -f scope=all
gh run watch -R 0x-d2/beacon-kit-runner
```

`ref` public deponun bir dalı ya da etiketidir; bir özellik dalını birleşmeden önce çekmek için onun adını verin
(`-f ref=0x-d2/watchos-companion-app-stats`).
