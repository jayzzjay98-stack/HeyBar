import XCTest
@testable import HeyBar

@MainActor
final class SystemPreferenceControllerTests: XCTestCase {
    func testHiddenFilesRefreshUsesCommandRunnerOutput() {
        let runner = MockSystemCommandRunner()
        runner.results[[ "/usr/bin/defaults", "read", "com.apple.finder", "AppleShowAllFiles" ]] =
            SystemCommandResult(status: 0, stdout: "true\n", stderr: "")

        let controller = HiddenFilesController(commandRunner: runner)

        XCTAssertTrue(controller.isEnabled)
        XCTAssertNil(controller.lastError)
    }

    func testHiddenFilesSetEnabledReportsApplyFailure() {
        let runner = MockSystemCommandRunner()
        runner.results[[ "/usr/bin/defaults", "read", "com.apple.finder", "AppleShowAllFiles" ]] =
            SystemCommandResult(status: 0, stdout: "false\n", stderr: "")
        runner.results[[ "/usr/bin/defaults", "write", "com.apple.finder", "AppleShowAllFiles", "-bool", "true" ]] =
            SystemCommandResult(status: 0, stdout: "", stderr: "")
        runner.results[[ "/usr/bin/killall", "Finder" ]] =
            SystemCommandResult(status: 1, stdout: "", stderr: "Finder could not be restarted.")

        let controller = HiddenFilesController(commandRunner: runner)
        controller.setEnabled(true)

        XCTAssertFalse(controller.isEnabled)
        XCTAssertEqual(controller.lastError, "Finder could not be restarted.")
    }
}
