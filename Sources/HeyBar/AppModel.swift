import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var selectedPage: SettingsPage? = .general
    @Published var selectedThemeID: String {
        didSet {
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

    init() {
        selectedThemeID = ThemeCatalog.persistedThemeID() ?? ThemeCatalog.fallbackTheme.id
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
