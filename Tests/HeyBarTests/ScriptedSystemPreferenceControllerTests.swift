import XCTest
@testable import HeyBar

@MainActor
final class ScriptedSystemPreferenceControllerTests: XCTestCase {
    func testHideDockRefreshFallsBackToDefaultsRead() {
        let scriptExecutor = MockAppleScriptExecutor()
        let commandRunner = MockSystemCommandRunner()
        scriptExecutor.results["tell application \"System Events\" to get the autohide of the dock preferences"] =
            .failure("Automation not allowed.")
        commandRunner.results[[ "/usr/bin/defaults", "read", "com.apple.dock", "autohide" ]] =
            SystemCommandResult(status: 0, stdout: "1\n", stderr: "")

        let controller = HideDockController(scriptExecutor: scriptExecutor, commandRunner: commandRunner)

        XCTAssertTrue(controller.isEnabled)
        XCTAssertEqual(controller.lastError, "Automation not allowed.")
    }

    func testHideBarSetEnabledSurfacesAppleScriptError() {
        let scriptExecutor = MockAppleScriptExecutor()
        scriptExecutor.defaultResult = .failure("Automation not allowed.")

        let controller = HideBarController(scriptExecutor: scriptExecutor, commandRunner: MockSystemCommandRunner())
        controller.setEnabled(true)

        XCTAssertFalse(controller.isEnabled)
        XCTAssertEqual(controller.lastError, "Automation not allowed.")
    }
}
