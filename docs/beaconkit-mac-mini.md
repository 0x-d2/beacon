# BeaconKit™ · Mac mini kurulumu

Katalog, evdeki Mac mini'de (`brain`) çalışan bir GitHub Actions runner'ı ile üretilir ve yalnız tailnet'e yayınlanır.
Ata-Online'ın `ata-kit` runner'ı aynı makinede durur; bu repo için ikinci, ayrı bir runner kurulur. Aşağıdakiler bir
kez yapılır. Referans: `docs/beaconkit.md` › Hosting.

## 1. Runner

GitHub'da: **0x-d2/beacon › Settings › Actions › Runners › New self-hosted runner** (macOS, ARM64). Sayfanın verdiği
indirme ve `config.sh` komutlarını mini'de, **ayrı bir klasörde** çalıştırın:

```sh
mkdir -p ~/actions-runner/beacon && cd ~/actions-runner/beacon
# … sayfadaki curl + tar satırları …
./config.sh --url https://github.com/0x-d2/beacon --token <SAYFADAKİ-TOKEN> \
  --name brain-beacon-kit --labels beacon-kit --unattended
./svc.sh install
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/actions.runner.0x-d2-beacon.brain-beacon-kit.plist
```

- Etiket yalnız `beacon-kit`: `kit.yml` bu etiketi ister, başka hiçbir workflow istemez.
- `./svc.sh start` SSH'tan GUI oturumunun dışına düşer; `launchctl bootstrap gui/…` kullanın (Ata'dakiyle aynı).
- Durum: `./svc.sh status`. Kaldırmak: `./svc.sh uninstall && ./config.sh remove --token <TOKEN>`.
- Repo public: **Settings › Actions › General › Fork pull request workflows** altında "Require approval for all
  external contributors" seçili kalsın. `kit.yml` zaten yalnız elle ve yalnız repo sahibi tetiklediğinde çalışır.

## 2. Node ve gh

`kit.yml` Node'u kendisi kurar (`actions/setup-node`, Node 25). `gh` Homebrew'den (`/opt/homebrew/bin`) gelir; revize
notlarını okumak için workflow kendi token'ını verir, mini'de ayrıca `gh auth login` gerekmez.

## 3. Caddy

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

## 4. Tailscale

```sh
tailscale serve --bg --https=8445 http://127.0.0.1:8789
tailscale serve status
```

8443 ve 8444 Ata'nın; onlara dokunmayın. Site: `https://brain.<tailnet>.ts.net:8445`. Paylaşılan kullanıcılara
yalnız bu portu açmak için Tailscale ACL'ine Ata'daki gibi `tcp:8445` ekleyin.

## 5. İlk çalıştırma

```sh
gh workflow run kit.yml -f scope=site --repo 0x-d2/beacon
gh run watch --repo 0x-d2/beacon
```

`kit.yml` main'de olmalı: `workflow_dispatch` yalnız varsayılan dalda tanımlı workflow'ları listeler.
