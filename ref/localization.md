# Localization

Every user-visible string ships translated in the same change. The owner reads Turkish first.

## iPhone, watch and complications (English + Turkish)

- One String Catalog for all three targets: `iOS/Beacon/Resources/Localizable.xcstrings` (source `en`, translation
  `tr`). The watch and the widgets compile the same file (`project.yml`).
- In code, write English: `Text("No Macs yet")`, `String(localized: "\(count) fans")`, `LocalizedStringKey` /
  `LocalizedStringResource` parameters. Numbers, bytes, rates, temperatures and durations go through `Format`
  (`Format.swift`), which follows the phone's region (`%23` in Turkish).
- `xcodebuild` doesn't write new keys into the catalog; add them yourself. Keep the file's JSON form exactly — it is
  what Python's `json.dumps(d, indent=2, ensure_ascii=False)` writes (`"key": value`, no newline at the end) — and its
  key order: insert a new key before the first existing key that sorts after it, never re-sort the file (a few keys
  are deliberately out of order). Load, insert, dump, and check `git diff` shows only your additions. Each entry:
  ```json
      "No fan readings": {
        "localizations": {
          "tr": {
            "stringUnit": {
              "state": "translated",
              "value": "Fan ölçümü yok"
            }
          }
        }
      },
  ```
  Strings that aren't words (`"%@ · %@"`) get `"shouldTranslate": false` instead.
- To find missing keys after a build: the targets' `*.stringsdata` under
  `build/DerivedData/Build/Intermediates.noindex/Beacon.build/*/*/Objects-normal/arm64/` list every key the code uses;
  each must exist in the catalog.
- **Turkish voice:** informal "sen" (`Mac’ini burada görmek için saatte Beacon’ı aç.`), typographic apostrophe `’` in
  suffixes (`Mac’te`, `iPhone’una`), Apple's Turkish terms (Ayarlar, Bildirim Merkezi, Evrensel Pano), short sentences.
  Product names stay: Beacon, Vorssaint, BeaconKit™, Tailscale, Apple Watch.
- Check screens in both languages: `-AppleLanguages "(tr)" -AppleLocale tr_TR` and `"(en)" en_US` at launch.

## Mac (15 languages)

- `Core/Localization.swift`: `AppLanguage` has 15 cases — enUS, ptBR, tr, ru, es, sk, de, fr, it, ja, ko, uk,
  zhHans, zhTW, zhHK. `L10n.shared.language` is the app's language (it can differ from the system's).
- General strings: `struct Strings` (`L10n.shared.s`), `enUS`/`ptBR` inline, the rest in
  `Core/Localizations/Strings+<Language>.swift`.
- A feature's strings: `Core/<Feature>Strings.swift` — a struct of `let` fields, one static value per language in the
  same file, and `extension FeatureStrings { static func <feature>(_ language: AppLanguage) -> … }` switching over every
  case (`Core/RemoteMonitorStrings.swift`). Use: `FeatureStrings.remoteMonitor(L10n.shared.language).addPhone`.
- Info.plist usage descriptions: `Resources/<lang>.lproj/InfoPlist.strings`, all 14 non-English folders.
- `Tests/LocalizationTests.swift` and `LocalizationFeatureContractTests.swift` enforce coverage
  (`./build.sh --test-suite=localization`).

## The BeaconKit™ site

Every string is written in both languages in place: `t('Renkler', 'Colours')` (`web/src`).
