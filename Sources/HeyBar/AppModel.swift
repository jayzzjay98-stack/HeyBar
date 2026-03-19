import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: SettingsPage? = .general
    @Published var selectedThemeID: String {
        didSet {
            guard oldValue != selectedThemeID else { return }
            UserDefaults.standard.set(selectedThemeID, forKey: ThemeCatalog.storageKey)
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

    // Observes UserDefaults so theme changes made by the Settings helper
    // process are picked up immediately in the main (status-bar) process.
    nonisolated(unsafe) private var defaultsObserver: NSObjectProtocol?

    init() {
        selectedThemeID = ThemeCatalog.persistedThemeID() ?? ThemeCatalog.fallbackTheme.id
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            let persisted = ThemeCatalog.persistedThemeID() ?? ThemeCatalog.fallbackTheme.id
            Task { @MainActor [weak self] in
                guard let self, persisted != self.selectedThemeID else { return }
                self.selectedThemeID = persisted
            }
        }
    }

    deinit {
        defaultsObserver.map { NotificationCenter.default.removeObserver($0) }
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
