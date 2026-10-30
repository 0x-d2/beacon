// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import Foundation

/// Settings › Monitor › iPhone card (UI/Settings/RemoteMonitorCard.swift).
struct RemoteMonitorFeatureStrings {
    let title: String
    let caption: String
    let addPhone: String
    let scanHint: String
    let copyLink: String
    let cancel: String
    let pairedPhones: String
    let noPhones: String
    let remove: String
    let connected: String
    let lastSeenFormat: String
    let neverConnected: String
    let listeningFormat: String
    let idle: String
    let failedFormat: String
    let remoteAddress: String
    let remoteAddressHelp: String
    let keychainFailed: String
}

extension FeatureStrings {
    static func remoteMonitor(_ language: AppLanguage) -> RemoteMonitorFeatureStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .sk: return .sk
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .uk: return .uk
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        }
    }
}

extension RemoteMonitorFeatureStrings {
    static let enUS = RemoteMonitorFeatureStrings(
        title: "Watch from iPhone",
        caption: "Sends this Mac’s readings to the Beacon app on the iPhones you pair, over your local network or Tailscale and nowhere else.",
        addPhone: "Add a phone", scanHint: "In Beacon, tap Add a Mac and scan this code. It works for 10 minutes.",
        copyLink: "Copy link", cancel: "Cancel", pairedPhones: "Paired phones", noPhones: "No phones paired yet.",
        remove: "Remove", connected: "Connected", lastSeenFormat: "Last seen %@", neverConnected: "Not connected yet",
        listeningFormat: "Listening on port %d", idle: "Starts listening once a phone is paired.",
        failedFormat: "Couldn’t start: %@", remoteAddress: "Address away from home",
        remoteAddressHelp: "The name your phone uses to reach this Mac when it’s not on the same network, such as its Tailscale name. Left empty, this Mac’s Tailscale address is used.",
        keychainFailed: "Couldn’t save the phone’s key to the keychain."
    )

    static let tr = RemoteMonitorFeatureStrings(
        title: "iPhone’dan izle",
        caption: "Bu Mac’in ölçümlerini eşleştirdiğin iPhone’lardaki Beacon uygulamasına gönderir; yalnız yerel ağ ya da Tailscale üzerinden, başka hiçbir yere.",
        addPhone: "Telefon ekle", scanHint: "Beacon’da Mac ekle’ye dokunup bu kodu okut. Kod 10 dakika geçerli.",
        copyLink: "Bağlantıyı kopyala", cancel: "Vazgeç", pairedPhones: "Eşleşen telefonlar", noPhones: "Henüz eşleşen telefon yok.",
        remove: "Kaldır", connected: "Bağlı", lastSeenFormat: "Son görülme: %@", neverConnected: "Henüz bağlanmadı",
        listeningFormat: "%d portunda dinliyor", idle: "Bir telefon eşleşince dinlemeye başlar.",
        failedFormat: "Başlatılamadı: %@", remoteAddress: "Evden uzaktayken adres",
        remoteAddressHelp: "Telefonun aynı ağda değilken bu Mac’e ulaşacağı ad, örneğin Tailscale adı. Boş bırakılırsa bu Mac’in Tailscale adresi kullanılır.",
        keychainFailed: "Telefonun anahtarı anahtar zincirine kaydedilemedi."
    )

    static let ptBR = RemoteMonitorFeatureStrings(
        title: "Acompanhar pelo iPhone",
        caption: "Envia as leituras deste Mac para o app Beacon nos iPhones que você parear, pela rede local ou pelo Tailscale e para nenhum outro lugar.",
        addPhone: "Adicionar telefone", scanHint: "No Beacon, toque em Adicionar Mac e leia este código. Ele vale por 10 minutos.",
        copyLink: "Copiar link", cancel: "Cancelar", pairedPhones: "Telefones pareados", noPhones: "Nenhum telefone pareado ainda.",
        remove: "Remover", connected: "Conectado", lastSeenFormat: "Visto por último %@", neverConnected: "Ainda não conectou",
        listeningFormat: "Escutando na porta %d", idle: "Começa a escutar quando um telefone for pareado.",
        failedFormat: "Não foi possível iniciar: %@", remoteAddress: "Endereço fora de casa",
        remoteAddressHelp: "O nome que o telefone usa para chegar a este Mac quando não está na mesma rede, como o nome no Tailscale. Se ficar vazio, usa o endereço Tailscale deste Mac.",
        keychainFailed: "Não foi possível salvar a chave do telefone nas Chaves."
    )

    static let ru = RemoteMonitorFeatureStrings(
        title: "Наблюдение с iPhone",
        caption: "Отправляет показатели этого Mac в приложение Beacon на сопряжённых iPhone: только по локальной сети или через Tailscale, больше никуда.",
        addPhone: "Добавить телефон", scanHint: "В Beacon нажмите «Добавить Mac» и отсканируйте код. Он действует 10 минут.",
        copyLink: "Скопировать ссылку", cancel: "Отмена", pairedPhones: "Сопряжённые телефоны", noPhones: "Сопряжённых телефонов пока нет.",
        remove: "Удалить", connected: "Подключён", lastSeenFormat: "Был в сети %@", neverConnected: "Ещё не подключался",
        listeningFormat: "Ожидает подключений на порту %d", idle: "Начнёт ожидать подключений, когда появится сопряжённый телефон.",
        failedFormat: "Не удалось запустить: %@", remoteAddress: "Адрес вне дома",
        remoteAddressHelp: "Имя, по которому телефон найдёт этот Mac вне общей сети, например имя в Tailscale. Если поле пустое, используется адрес этого Mac в Tailscale.",
        keychainFailed: "Не удалось сохранить ключ телефона в связке ключей."
    )

    static let es = RemoteMonitorFeatureStrings(
        title: "Ver desde el iPhone",
        caption: "Envía las lecturas de este Mac a la app Beacon de los iPhone que vincules, por tu red local o por Tailscale y a ningún otro sitio.",
        addPhone: "Añadir teléfono", scanHint: "En Beacon, toca Añadir Mac y escanea este código. Sirve durante 10 minutos.",
        copyLink: "Copiar enlace", cancel: "Cancelar", pairedPhones: "Teléfonos vinculados", noPhones: "Aún no hay teléfonos vinculados.",
        remove: "Quitar", connected: "Conectado", lastSeenFormat: "Visto por última vez %@", neverConnected: "Aún no se ha conectado",
        listeningFormat: "Escuchando en el puerto %d", idle: "Empieza a escuchar cuando vinculas un teléfono.",
        failedFormat: "No se pudo iniciar: %@", remoteAddress: "Dirección fuera de casa",
        remoteAddressHelp: "El nombre con el que el teléfono llega a este Mac cuando no está en la misma red, como su nombre en Tailscale. Si se deja vacío, se usa la dirección Tailscale de este Mac.",
        keychainFailed: "No se pudo guardar la clave del teléfono en el llavero."
    )

    static let sk = RemoteMonitorFeatureStrings(
        title: "Sledovať z iPhonu",
        caption: "Posiela údaje tohto Macu do aplikácie Beacon na spárovaných iPhonoch, len cez miestnu sieť alebo Tailscale a nikam inam.",
        addPhone: "Pridať telefón", scanHint: "V Beacon klepnite na Pridať Mac a naskenujte tento kód. Platí 10 minút.",
        copyLink: "Kopírovať odkaz", cancel: "Zrušiť", pairedPhones: "Spárované telefóny", noPhones: "Zatiaľ žiadny spárovaný telefón.",
        remove: "Odstrániť", connected: "Pripojený", lastSeenFormat: "Naposledy %@", neverConnected: "Zatiaľ sa nepripojil",
        listeningFormat: "Počúva na porte %d", idle: "Začne počúvať, keď spárujete telefón.",
        failedFormat: "Nepodarilo sa spustiť: %@", remoteAddress: "Adresa mimo domu",
        remoteAddressHelp: "Názov, cez ktorý sa telefón dostane k tomuto Macu mimo rovnakej siete, napríklad názov v Tailscale. Ak je prázdne, použije sa adresa tohto Macu v Tailscale.",
        keychainFailed: "Kľúč telefónu sa nepodarilo uložiť do kľúčenky."
    )

    static let de = RemoteMonitorFeatureStrings(
        title: "Vom iPhone aus beobachten",
        caption: "Sendet die Messwerte dieses Macs an die Beacon-App auf den gekoppelten iPhones, nur über dein lokales Netzwerk oder Tailscale und sonst nirgendwohin.",
        addPhone: "Telefon hinzufügen", scanHint: "Tippe in Beacon auf „Mac hinzufügen“ und scanne diesen Code. Er gilt 10 Minuten.",
        copyLink: "Link kopieren", cancel: "Abbrechen", pairedPhones: "Gekoppelte Telefone", noPhones: "Noch keine Telefone gekoppelt.",
        remove: "Entfernen", connected: "Verbunden", lastSeenFormat: "Zuletzt gesehen %@", neverConnected: "Noch nicht verbunden",
        listeningFormat: "Wartet auf Port %d", idle: "Wartet auf Verbindungen, sobald ein Telefon gekoppelt ist.",
        failedFormat: "Start fehlgeschlagen: %@", remoteAddress: "Adresse unterwegs",
        remoteAddressHelp: "Der Name, über den das Telefon diesen Mac außerhalb desselben Netzwerks erreicht, etwa sein Tailscale-Name. Leer gelassen wird die Tailscale-Adresse dieses Macs verwendet.",
        keychainFailed: "Der Schlüssel des Telefons konnte nicht im Schlüsselbund gesichert werden."
    )

    static let fr = RemoteMonitorFeatureStrings(
        title: "Suivre depuis l’iPhone",
        caption: "Envoie les relevés de ce Mac à l’app Beacon des iPhone que vous jumelez, par votre réseau local ou Tailscale, et nulle part ailleurs.",
        addPhone: "Ajouter un téléphone", scanHint: "Dans Beacon, touchez Ajouter un Mac et scannez ce code. Il est valable 10 minutes.",
        copyLink: "Copier le lien", cancel: "Annuler", pairedPhones: "Téléphones jumelés", noPhones: "Aucun téléphone jumelé pour l’instant.",
        remove: "Retirer", connected: "Connecté", lastSeenFormat: "Vu pour la dernière fois %@", neverConnected: "Pas encore connecté",
        listeningFormat: "À l’écoute sur le port %d", idle: "Se met à l’écoute dès qu’un téléphone est jumelé.",
        failedFormat: "Démarrage impossible : %@", remoteAddress: "Adresse hors de chez vous",
        remoteAddressHelp: "Le nom par lequel le téléphone joint ce Mac hors du même réseau, comme son nom Tailscale. Laissé vide, l’adresse Tailscale de ce Mac est utilisée.",
        keychainFailed: "Impossible d’enregistrer la clé du téléphone dans le trousseau."
    )

    static let it = RemoteMonitorFeatureStrings(
        title: "Guarda dall’iPhone",
        caption: "Invia le letture di questo Mac all’app Beacon sugli iPhone abbinati, tramite la rete locale o Tailscale e da nessun’altra parte.",
        addPhone: "Aggiungi telefono", scanHint: "In Beacon tocca Aggiungi Mac e inquadra questo codice. Vale 10 minuti.",
        copyLink: "Copia link", cancel: "Annulla", pairedPhones: "Telefoni abbinati", noPhones: "Ancora nessun telefono abbinato.",
        remove: "Rimuovi", connected: "Connesso", lastSeenFormat: "Visto l’ultima volta %@", neverConnected: "Non ancora connesso",
        listeningFormat: "In ascolto sulla porta %d", idle: "Si mette in ascolto quando abbini un telefono.",
        failedFormat: "Impossibile avviare: %@", remoteAddress: "Indirizzo fuori casa",
        remoteAddressHelp: "Il nome con cui il telefono raggiunge questo Mac fuori dalla stessa rete, come il nome Tailscale. Se vuoto, si usa l’indirizzo Tailscale di questo Mac.",
        keychainFailed: "Impossibile salvare la chiave del telefono nel portachiavi."
    )

    static let ja = RemoteMonitorFeatureStrings(
        title: "iPhoneで見る",
        caption: "このMacの計測値を、ペアリングしたiPhoneのBeaconアプリに送ります。ローカルネットワークかTailscale経由のみで、ほかには送りません。",
        addPhone: "電話を追加", scanHint: "Beaconで「Macを追加」をタップしてこのコードを読み取ります。有効期間は10分です。",
        copyLink: "リンクをコピー", cancel: "キャンセル", pairedPhones: "ペアリング済みの電話", noPhones: "ペアリングした電話はまだありません。",
        remove: "削除", connected: "接続中", lastSeenFormat: "最終接続 %@", neverConnected: "まだ接続していません",
        listeningFormat: "ポート%dで待機中", idle: "電話をペアリングすると待機を始めます。",
        failedFormat: "開始できませんでした: %@", remoteAddress: "外出先からのアドレス",
        remoteAddressHelp: "同じネットワークにいないときに電話がこのMacに接続する名前（Tailscaleの名前など）。空欄の場合はこのMacのTailscaleアドレスを使います。",
        keychainFailed: "電話の鍵をキーチェーンに保存できませんでした。"
    )

    static let ko = RemoteMonitorFeatureStrings(
        title: "iPhone에서 보기",
        caption: "이 Mac의 측정값을 페어링한 iPhone의 Beacon 앱으로 보냅니다. 로컬 네트워크나 Tailscale로만 보내며 다른 곳으로는 보내지 않습니다.",
        addPhone: "전화 추가", scanHint: "Beacon에서 Mac 추가를 탭하고 이 코드를 스캔하세요. 10분 동안 유효합니다.",
        copyLink: "링크 복사", cancel: "취소", pairedPhones: "페어링된 전화", noPhones: "아직 페어링된 전화가 없습니다.",
        remove: "제거", connected: "연결됨", lastSeenFormat: "마지막 연결 %@", neverConnected: "아직 연결되지 않음",
        listeningFormat: "포트 %d에서 대기 중", idle: "전화를 페어링하면 대기를 시작합니다.",
        failedFormat: "시작할 수 없음: %@", remoteAddress: "외부에서 쓸 주소",
        remoteAddressHelp: "같은 네트워크에 있지 않을 때 전화가 이 Mac에 연결하는 이름(예: Tailscale 이름). 비워 두면 이 Mac의 Tailscale 주소를 사용합니다.",
        keychainFailed: "전화의 키를 키체인에 저장할 수 없습니다."
    )

    static let uk = RemoteMonitorFeatureStrings(
        title: "Стеження з iPhone",
        caption: "Надсилає показники цього Mac у застосунок Beacon на спарених iPhone: лише через локальну мережу або Tailscale, більше нікуди.",
        addPhone: "Додати телефон", scanHint: "У Beacon торкніться «Додати Mac» і відскануйте цей код. Він діє 10 хвилин.",
        copyLink: "Копіювати посилання", cancel: "Скасувати", pairedPhones: "Спарені телефони", noPhones: "Спарених телефонів поки немає.",
        remove: "Видалити", connected: "Підключено", lastSeenFormat: "Востаннє %@", neverConnected: "Ще не підключався",
        listeningFormat: "Очікує з’єднань на порту %d", idle: "Почне очікувати з’єднань, коли з’явиться спарений телефон.",
        failedFormat: "Не вдалося запустити: %@", remoteAddress: "Адреса поза домом",
        remoteAddressHelp: "Назва, за якою телефон знайде цей Mac поза спільною мережею, наприклад назва в Tailscale. Якщо поле порожнє, використовується адреса цього Mac у Tailscale.",
        keychainFailed: "Не вдалося зберегти ключ телефона у в’язці ключів."
    )

    static let zhHans = RemoteMonitorFeatureStrings(
        title: "在 iPhone 上查看",
        caption: "将这台 Mac 的读数发送到已配对 iPhone 上的 Beacon App，仅通过本地网络或 Tailscale，不会发送到其他任何地方。",
        addPhone: "添加手机", scanHint: "在 Beacon 中轻点“添加 Mac”并扫描此代码。代码 10 分钟内有效。",
        copyLink: "拷贝链接", cancel: "取消", pairedPhones: "已配对的手机", noPhones: "尚未配对任何手机。",
        remove: "移除", connected: "已连接", lastSeenFormat: "上次连接 %@", neverConnected: "尚未连接",
        listeningFormat: "正在端口 %d 上监听", idle: "配对手机后开始监听。",
        failedFormat: "无法启动：%@", remoteAddress: "外出时的地址",
        remoteAddressHelp: "手机不在同一网络时用来连接这台 Mac 的名称，例如它的 Tailscale 名称。留空则使用这台 Mac 的 Tailscale 地址。",
        keychainFailed: "无法将手机的密钥存储到钥匙串。"
    )

    static let zhTW = RemoteMonitorFeatureStrings(
        title: "在 iPhone 上查看",
        caption: "將這台 Mac 的讀數傳送到已配對 iPhone 上的 Beacon App，只透過區域網路或 Tailscale，不會傳到其他地方。",
        addPhone: "加入手機", scanHint: "在 Beacon 中點一下「加入 Mac」並掃描此代碼。代碼 10 分鐘內有效。",
        copyLink: "拷貝連結", cancel: "取消", pairedPhones: "已配對的手機", noPhones: "尚未配對任何手機。",
        remove: "移除", connected: "已連線", lastSeenFormat: "上次連線 %@", neverConnected: "尚未連線",
        listeningFormat: "正在埠號 %d 上監聽", idle: "配對手機後開始監聽。",
        failedFormat: "無法啟動：%@", remoteAddress: "外出時的位址",
        remoteAddressHelp: "手機不在同一網路時用來連線這台 Mac 的名稱，例如它的 Tailscale 名稱。留空則使用這台 Mac 的 Tailscale 位址。",
        keychainFailed: "無法將手機的密鑰儲存到鑰匙圈。"
    )

    static let zhHK = RemoteMonitorFeatureStrings(
        title: "在 iPhone 上查看",
        caption: "將這部 Mac 的讀數傳送到已配對 iPhone 上的 Beacon App，只會經區域網絡或 Tailscale，不會傳到其他地方。",
        addPhone: "加入手機", scanHint: "在 Beacon 中點一下「加入 Mac」並掃描此代碼。代碼 10 分鐘內有效。",
        copyLink: "拷貝連結", cancel: "取消", pairedPhones: "已配對的手機", noPhones: "尚未配對任何手機。",
        remove: "移除", connected: "已連線", lastSeenFormat: "上次連線 %@", neverConnected: "尚未連線",
        listeningFormat: "正在埠號 %d 上監聽", idle: "配對手機後開始監聽。",
        failedFormat: "無法啟動：%@", remoteAddress: "外出時的位址",
        remoteAddressHelp: "手機不在同一網絡時用來連線這部 Mac 的名稱，例如它的 Tailscale 名稱。留空則使用這部 Mac 的 Tailscale 位址。",
        keychainFailed: "無法將手機的密鑰儲存到鑰匙圈。"
    )
}
