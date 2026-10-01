import AppKit
import SwiftUI
import CoreGraphics
import ServiceManagement
import Darwin

struct ScrollPolicy {
    var wheel: Bool
    var touch: Bool
    var vertical: Bool
    var horizontal: Bool

    func transform(_ event: CGEvent) {
        let isTouch = Self.isTouchEvent(event)
        guard isTouch ? touch : wheel else { return }
        if vertical { reverse(event, fields: [.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1]) }
        if horizontal { reverse(event, fields: [.scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2]) }
    }

    static func isTouchEvent(_ event: CGEvent) -> Bool {
        // Smooth mouse drivers also generate continuous events. Gesture phases
        // and momentum are stronger evidence of a touch gesture.
        return event.getIntegerValueField(.scrollWheelEventScrollPhase) != 0
            || event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
    }

    private func reverse(_ event: CGEvent, fields: [CGEventField]) {
        let values = fields.map { event.getDoubleValueField($0) }
        // Set fixed-point last: setting line deltas also updates fixed-point fields.
        for index in [0, 2, 1] {
            let field = fields[index]
            if index == 1 {
                event.setDoubleValueField(field, value: -values[index])
            } else {
                event.setIntegerValueField(field, value: -Int64(values[index]))
            }
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, tr, de, fr
    var id: String { rawValue }
    var name: String {
        switch self {
        case .en: return "English"
        case .tr: return "Türkçe"
        case .de: return "Deutsch"
        case .fr: return "Français"
        }
    }
    func text(_ key: String) -> String {
        let index: Int
        switch self { case .en: index = 0; case .tr: index = 1; case .de: index = 2; case .fr: index = 3 }
        return Self.translations[key]?[index] ?? Self.translations[key]?[0] ?? key
    }
    static let translations: [String: [String]] = [
        "active": ["Active", "Etkin", "Aktiv", "Actif"],
        "off": ["Off", "Kapalı", "Aus", "Désactivé"],
        "enabled": ["Enable RouScroll", "RouScroll’u etkinleştir", "RouScroll aktivieren", "Activer RouScroll"],
        "logo": ["RouScroll logo", "RouScroll logosu", "RouScroll-Logo", "Logo RouScroll"],
        "devices": ["DEVICES", "CİHAZLAR", "GERÄTE", "APPAREILS"],
        "mouse": ["Mouse wheel", "Fare tekerleği", "Mausrad", "Molette de souris"],
        "trackpad": ["Trackpad", "Trackpad", "Trackpad", "Trackpad"],
        "directions": ["REVERSE DIRECTIONS", "TERS ÇEVRİLECEK YÖNLER", "RICHTUNG UMKEHREN", "INVERSER LE DÉFILEMENT"],
        "vertical": ["Vertical scrolling", "Dikey kaydırma", "Vertikales Scrollen", "Défilement vertical"],
        "horizontal": ["Horizontal scrolling", "Yatay kaydırma", "Horizontales Scrollen", "Défilement horizontal"],
        "settings": ["Settings", "Ayarlar", "Einstellungen", "Réglages"],
        "back": ["Back", "Geri", "Zurück", "Retour"],
        "language": ["Language", "Dil", "Sprache", "Langue"],
        "general": ["GENERAL", "GENEL", "ALLGEMEIN", "GÉNÉRAL"],
        "launch": ["Launch at login", "Mac açıldığında başlat", "Beim Anmelden starten", "Ouvrir à la connexion"],
        "quit": ["Quit", "Çıkış", "Beenden", "Quitter"],
        "permissionTitle": ["RouScroll needs permission", "RouScroll için izin gerekiyor", "RouScroll benötigt eine Berechtigung", "RouScroll a besoin d’une autorisation"],
        "permissionBody": ["To change scrolling direction, allow this copy of RouScroll in System Settings → Privacy & Security → Accessibility. Scrolling will start automatically once permission is granted.", "Kaydırma yönünü değiştirmek için Sistem Ayarları → Gizlilik ve Güvenlik → Erişilebilirlik bölümünde bu RouScroll uygulamasına izin ver. İzin verildiğinde otomatik başlayacak.", "Erlaube diese Version von RouScroll unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen. Das Scrollen startet automatisch, sobald die Berechtigung erteilt wurde.", "Pour changer le sens du défilement, autorisez cette version de RouScroll dans Réglages Système → Confidentialité et sécurité → Accessibilité. Le défilement démarrera automatiquement après l’autorisation."],
        "failedTitle": ["Scrolling could not start", "Kaydırma başlatılamadı", "Scrollen konnte nicht gestartet werden", "Impossible de démarrer le défilement"],
        "failedBody": ["macOS could not open the scroll filter. Check the RouScroll entry in Accessibility settings and try again.", "macOS kaydırma filtresini açamadı. Erişilebilirlik bölümündeki RouScroll kaydını kontrol edip tekrar dene.", "macOS konnte den Scrollfilter nicht öffnen. Überprüfe den RouScroll-Eintrag unter Bedienungshilfen und versuche es erneut.", "macOS n’a pas pu ouvrir le filtre de défilement. Vérifiez RouScroll dans les réglages d’accessibilité, puis réessayez."],
        "openSettings": ["Open System Settings", "Sistem Ayarlarını aç", "Systemeinstellungen öffnen", "Ouvrir les Réglages Système"],
        "notNow": ["Not now", "Şimdi değil", "Nicht jetzt", "Pas maintenant"],
        "loginApproval": ["Approve RouScroll in System Settings → General → Login Items.", "Sistem Ayarları → Genel → Giriş Öğeleri bölümünde RouScroll’u onayla.", "Bestätige RouScroll unter Systemeinstellungen → Allgemein → Anmeldeobjekte.", "Autorisez RouScroll dans Réglages Système → Général → Ouverture."],
        "loginFailure": ["Could not change launch at login.", "Başlangıç ayarı değiştirilemedi.", "Der automatische Start konnte nicht geändert werden.", "Impossible de modifier l’ouverture à la connexion."],
        "menuHint": ["RouScroll — scroll direction", "RouScroll — kaydırma yönü", "RouScroll — Scrollrichtung", "RouScroll — sens du défilement"]
    ]
}

final class Settings: ObservableObject {
    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "language")
            languageChanged?()
        }
    }
    var languageChanged: (() -> Void)?
    func text(_ key: String) -> String { language.text(key) }

    @Published var enabled: Bool { didSet { save(); changed?() } }
    @Published var wheel: Bool { didSet { save(); changed?() } }
    @Published var touch: Bool { didSet { save(); changed?() } }
    @Published var vertical: Bool { didSet { save(); changed?() } }
    @Published var horizontal: Bool { didSet { save(); changed?() } }
    @Published var status = "Erişilebilirlik izni bekleniyor"
    @Published var running = false
    @Published var login = SMAppService.mainApp.status == .enabled
    @Published var loginErrorKey = ""
    var changed: (() -> Void)?
    var policy: ScrollPolicy { ScrollPolicy(wheel: wheel, touch: touch, vertical: vertical, horizontal: horizontal) }
    init() {
        let d = UserDefaults.standard
        d.register(defaults: ["enabled": true, "wheel": true, "touch": false, "vertical": true, "horizontal": false])
        language = AppLanguage(rawValue: d.string(forKey: "language") ?? "en") ?? .en
        enabled = d.bool(forKey: "enabled"); wheel = d.bool(forKey: "wheel")
        touch = d.bool(forKey: "touch"); vertical = d.bool(forKey: "vertical"); horizontal = d.bool(forKey: "horizontal")
    }
    func save() {
        let d = UserDefaults.standard
        for (key, value) in [("enabled", enabled), ("wheel", wheel), ("touch", touch), ("vertical", vertical), ("horizontal", horizontal)] { d.set(value, forKey: key) }
    }
    func setLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            login = SMAppService.mainApp.status == .enabled
            loginErrorKey = SMAppService.mainApp.status == .requiresApproval ? "loginApproval" : ""
        } catch { loginErrorKey = "loginFailure"; login = SMAppService.mainApp.status == .enabled }
    }
}

final class ScrollEngine {
    let settings: Settings
    var tap: CFMachPort?
    var source: CFRunLoopSource?
    init(_ settings: Settings) { self.settings = settings }
    func update() {
        guard settings.enabled else { stop(); settings.status = "Kaydırma yönü değiştirilmeden geçiyor"; return }
        guard AXIsProcessTrusted() else { stop(); settings.status = "Kapalı"; return }
        if let tap, CFMachPortIsValid(tap) {
            CGEvent.tapEnable(tap: tap, enable: true)
            settings.running = CGEvent.tapIsEnabled(tap: tap)
            settings.status = settings.running ? "Kaydırma kontrolü etkin" : "Başlatılamadı"
            return
        }
        stop()
        let mask = CGEventMask(1) << CGEventType.scrollWheel.rawValue
        tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: mask, callback: { _, type, event, context in
            guard let context else { return Unmanaged.passUnretained(event) }
            let engine = Unmanaged<ScrollEngine>.fromOpaque(context).takeUnretainedValue()
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if engine.settings.enabled, let tap = engine.tap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                    engine.settings.running = CGEvent.tapIsEnabled(tap: tap)
                }
            } else if type == .scrollWheel, engine.settings.enabled { engine.settings.policy.transform(event) }
            return Unmanaged.passUnretained(event)
        }, userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else { settings.status = "Kaydırma erişimi açılamadı. İzinleri kontrol et."; settings.running = false; return }
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let source { CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes) }
        CGEvent.tapEnable(tap: tap, enable: true)
        settings.running = CGEvent.tapIsEnabled(tap: tap); settings.status = settings.running ? "Kaydırma kontrolü etkin" : "Başlatılamadı"
    }
    func stop() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false); CFMachPortInvalidate(tap) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil; tap = nil; settings.running = false
    }
}

struct MenuGlass: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct SettingsView: View {
    @ObservedObject var settings: Settings
    var setActive: (Bool) -> Void
    @State private var showingSettings = false

    func control(_ title: String, value: Binding<Bool>) -> some View {
        Toggle(title, isOn: value)
            .labelsHidden().toggleStyle(.switch).controlSize(.small)
            .fixedSize().frame(width: 38, alignment: .trailing)
            .accessibilityLabel(title)
    }

    func row(_ title: String, icon: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title).font(.system(size: 13)).lineLimit(1)
            Spacer(minLength: 8)
            control(title, value: value)
        }
        .frame(maxWidth: .infinity).frame(height: 36)
        .contentShape(Rectangle())
    }

    func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary).padding(.leading, 12)
            VStack(spacing: 0, content: content)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.06), lineWidth: 0.5))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(nsImage: AppBrand.logo)
                    .resizable().scaledToFit().frame(width: 36, height: 36)
                    .accessibilityLabel(settings.text("logo"))
                VStack(alignment: .leading, spacing: 3) {
                    Text("RouScroll").font(.system(size: 17, weight: .semibold))
                    HStack(spacing: 5) {
                        Circle().fill(settings.running ? Color.green : Color.orange).frame(width: 5, height: 5)
                        Text(settings.text(settings.running ? "active" : "off"))
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                control(settings.text("enabled"), value: Binding(get: { settings.running }, set: { setActive($0) }))
            }.padding(.horizontal, 12).padding(.vertical, 3)

            if showingSettings {
                HStack {
                    Button { showingSettings = false } label: {
                        Label(settings.text("back"), systemImage: "chevron.left")
                            .font(.system(size: 12))
                    }.buttonStyle(.plain).foregroundStyle(.secondary)
                    Spacer()
                    Text(settings.text("settings")).font(.system(size: 13, weight: .semibold))
                }.padding(.horizontal, 12)
                section(settings.text("general")) {
                    HStack(spacing: 10) {
                        Image(systemName: "globe").font(.system(size: 14)).foregroundStyle(.secondary).frame(width: 20)
                        Text(settings.text("language")).font(.system(size: 13))
                        Spacer(minLength: 8)
                        Picker(settings.text("language"), selection: $settings.language) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.name).tag(language)
                            }
                        }.labelsHidden().pickerStyle(.menu).frame(width: 136)
                            .accessibilityLabel(settings.text("language"))
                    }.frame(height: 36)
                    Divider().padding(.leading, 30)
                    row(settings.text("launch"), icon: "power", value: Binding(get: { settings.login }, set: { settings.setLogin($0) }))
                }
                if !settings.loginErrorKey.isEmpty {
                    Text(settings.text(settings.loginErrorKey)).font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 12)
                }
            } else {
                section(settings.text("devices")) {
                    row(settings.text("mouse"), icon: "computermouse", value: $settings.wheel)
                    Divider().padding(.leading, 30)
                    row(settings.text("trackpad"), icon: "hand.draw", value: $settings.touch)
                }
                section(settings.text("directions")) {
                    row(settings.text("vertical"), icon: "arrow.up.arrow.down", value: $settings.vertical)
                    Divider().padding(.leading, 30)
                    row(settings.text("horizontal"), icon: "arrow.left.arrow.right", value: $settings.horizontal)
                }
            }
            Divider()
            HStack {
                if !showingSettings {
                    Button { showingSettings = true } label: {
                        Label(settings.text("settings"), systemImage: "gearshape").font(.system(size: 11))
                    }.buttonStyle(.plain).foregroundStyle(.secondary)
                }
                Spacer()
                Button { NSApp.terminate(nil) } label: {
                    Label(settings.text("quit"), systemImage: "power").font(.system(size: 11))
                }.buttonStyle(.plain).foregroundStyle(.secondary)
            }.padding(.horizontal, 12)
        }
        .padding(16).frame(width: 328)
        .background(MenuGlass())
    }
}

enum AppBrand {
    static let logo: NSImage = {
        guard let path = Bundle.main.path(forResource: "Logo", ofType: "png"),
              let image = NSImage(contentsOfFile: path) else { return NSImage() }
        return image
    }()
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings = Settings()
    lazy var engine = ScrollEngine(settings)
    var item: NSStatusItem!
    let popover = NSPopover()
    var timer: Timer?
    var instanceLock: Int32 = -1
    var permissionAlertShown = false
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent two copies from reversing each other's scroll events.
        instanceLock = Darwin.open("/tmp/\(Bundle.main.bundleIdentifier ?? "com.rouscroll.mac")-\(getuid()).lock", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard instanceLock >= 0, flock(instanceLock, LOCK_EX | LOCK_NB) == 0 else {
            NSApp.terminate(nil); return
        }
        NSApp.setActivationPolicy(.accessory)
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let menuLogo = AppBrand.logo.copy() as! NSImage
        menuLogo.size = NSSize(width: 18, height: 18)
        menuLogo.isTemplate = true
        item.button?.image = menuLogo
        item.button?.setAccessibilityLabel("RouScroll")
        item.button?.toolTip = settings.text("menuHint")
        settings.languageChanged = { [weak self] in
            guard let self else { return }; self.item.button?.toolTip = self.settings.text("menuHint")
        }
        item.button?.target = self
        item.button?.action = #selector(togglePanel)
        popover.behavior = .transient
        popover.animates = true
        let controller = NSHostingController(rootView: SettingsView(settings: settings, setActive: { [weak self] on in
            self?.setActive(on)
        }))
        controller.sizingOptions = [.preferredContentSize]
        popover.contentViewController = controller
        settings.changed = { [weak self] in self?.engine.update() }
        engine.update()
        if settings.enabled && !settings.running {
            DispatchQueue.main.async { [weak self] in self?.requestStartPermission() }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.settings.enabled {
                let healthy = self.engine.tap.map { CFMachPortIsValid($0) && CGEvent.tapIsEnabled(tap: $0) } ?? false
                if !healthy { self.engine.update() }
            }
        }
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(woke), name: NSWorkspace.didWakeNotification, object: nil)
    }
    func setActive(_ on: Bool) {
        settings.enabled = on
        if on {
            engine.update()
            if !settings.running { requestStartPermission() }
        }
    }
    func requestStartPermission() {
        guard !settings.running, !permissionAlertShown else { return }
        permissionAlertShown = true
        defer { permissionAlertShown = false }
        popover.performClose(nil)
        let alert = NSAlert()
        alert.messageText = settings.text(AXIsProcessTrusted() ? "failedTitle" : "permissionTitle")
        alert.informativeText = settings.text(AXIsProcessTrusted() ? "failedBody" : "permissionBody")
        alert.addButton(withTitle: settings.text("openSettings"))
        alert.addButton(withTitle: settings.text("notNow"))
        alert.icon = AppBrand.logo
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
        engine.update()
    }
    @objc func togglePanel() {
        if popover.isShown { popover.performClose(nil) }
        else { showPanel() }
    }
    func showPanel() {
        guard let button = item.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showPanel()
        return false
    }
    @objc func woke() { engine.stop(); engine.update() }
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate(); engine.stop()
        if instanceLock >= 0 { Darwin.close(instanceLock) }
    }
}

func selfTest() {
    func event(continuous: Bool) -> CGEvent {
        let e = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: 7, wheel2: -3, wheel3: 0)!
        e.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
        e.setIntegerValueField(.scrollWheelEventScrollPhase, value: continuous ? 1 : 0)
        return e
    }
    let fields: [CGEventField] = [.scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1, .scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2]
    var checks = 0
    for continuous in [false, true] { for wheel in [false, true] { for touch in [false, true] { for vertical in [false, true] { for horizontal in [false, true] {
        let e = event(continuous: continuous); let before = fields.map { e.getDoubleValueField($0) }
        ScrollPolicy(wheel: wheel, touch: touch, vertical: vertical, horizontal: horizontal).transform(e)
        for (i, f) in fields.enumerated() {
            let reverse = (continuous ? touch : wheel) && (i < 3 ? vertical : horizontal)
            precondition(e.getDoubleValueField(f) == (reverse ? -before[i] : before[i]), "field \(f), before \(before[i]), after \(e.getDoubleValueField(f))")
            checks += 1
        }
    } } } } }
    let smoothMouse = event(continuous: true)
    smoothMouse.setIntegerValueField(.scrollWheelEventScrollPhase, value: 0)
    precondition(!ScrollPolicy.isTouchEvent(smoothMouse))
    smoothMouse.setIntegerValueField(.scrollWheelEventMomentumPhase, value: 1)
    precondition(ScrollPolicy.isTouchEvent(smoothMouse))
    for language in AppLanguage.allCases {
        for (key, values) in AppLanguage.translations {
            precondition(values.count == AppLanguage.allCases.count && !language.text(key).isEmpty)
        }
    }
    precondition(AppLanguage(rawValue: "invalid") == nil)
    print("PASS: \(checks) scroll field checks; mouse/touch classification; \(AppLanguage.translations.count) translations × 4 languages")
}

if CommandLine.arguments.contains("--self-test") { selfTest() }
else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
