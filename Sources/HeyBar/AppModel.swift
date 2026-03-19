import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: SettingsPage? = .general
    @Published var selectedThemeID: String {
        didSet {
            guard oldValue != selectedThemeID else { return }
            UserDefaults.standard.set(selectedThemeID, forKey: ThemeCatalog.storageKey)
            // Broadcast to other processes (e.g. main app ← settings helper)
            DistributedNotificationCenter.default().postNotificationName(
                AppModel.themeDidChangeNotification,
                object: Bundle.main.bundleIdentifier,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    }
    lazy var updater = InAppUpdater()
    let keepAwake = KeepAwakeController()
    let hiddenFiles = HiddenFilesController()
    let fileExtensions = ShowFileExtensionsController()
    let keyLight = KeyLightController()
    let nightShift = NightShiftController()
    let hideDock = HideDockController()
    let hideBar = HideBarController()
    let cleanKey = CleanKeyController()
    lazy var shortcuts = ShortcutController { [weak self] action in
        guard let self else { return }
        Task { @MainActor in
            self.performShortcutAction(action)
        }
    }

    var onQuit: (() -> Void)?

    static let themeDidChangeNotification = Notification.Name("com.gravity.heybar.themeDidChange")

    nonisolated(unsafe) private var themeObserver: NSObjectProtocol?

    init() {
        selectedThemeID = ThemeCatalog.persistedThemeID() ?? ThemeCatalog.fallbackTheme.id
        // Listen for theme changes posted by the Settings helper process.
        themeObserver = DistributedNotificationCenter.default().addObserver(
            forName: AppModel.themeDidChangeNotification,
            object: Bundle.main.bundleIdentifier,
            queue: .main
        ) { [weak self] _ in
            let persisted = ThemeCatalog.persistedThemeID() ?? ThemeCatalog.fallbackTheme.id
            Task { @MainActor [weak self] in
                guard let self, persisted != self.selectedThemeID else { return }
                self.selectedThemeID = persisted
            }
        }
    }

    deinit {
        themeObserver.map { DistributedNotificationCenter.default().removeObserver($0) }
    }

    var selectedTheme: AppTheme {
        ThemeCatalog.theme(for: selectedThemeID)
    }

    func toggleKeepAwake() {
        keepAwake.isEnabled.toggle()
    }

    func toggleCleanKey() {
        if cleanKey.isCleaning {
            cleanKey.stopCleaning()
        } else {
            _ = cleanKey.startCleaning()
        }
    }

    func toggleHiddenFiles() {
        hiddenFiles.setEnabled(!hiddenFiles.isEnabled)
    }

    func toggleFileExtensions() {
        fileExtensions.toggle()
    }

    func toggleKeyLight() {
        keyLight.toggle()
    }

    func toggleNightShift() {
        nightShift.toggle()
    }

    func toggleHideDock() {
        hideDock.toggle()
    }

    func toggleHideBar() {
        hideBar.toggle()
    }

    @discardableResult
    func startCleanKey() -> Bool {
        cleanKey.startCleaning()
    }

    func stopCleanKey() {
        cleanKey.stopCleaning()
    }

    private func performShortcutAction(_ action: ShortcutAction) {
        switch action {
        case .keepAwake:
            toggleKeepAwake()
        case .cleanKey:
            toggleCleanKey()
        case .showHiddenFiles:
            toggleHiddenFiles()
        case .showFileExtensions:
            toggleFileExtensions()
        case .keyLight:
            toggleKeyLight()
        case .nightShift:
            toggleNightShift()
        case .hideDock:
            toggleHideDock()
        case .hideBar:
            toggleHideBar()
        }
    }
}
