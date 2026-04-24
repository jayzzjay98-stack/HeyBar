import Foundation
import AppKit

@MainActor
final class InAppUpdater: ObservableObject {

    enum State {
        case idle
        case checking
        case upToDate
        case available(version: String, downloadURL: String)
        case downloading
        case downloaded(version: String, zipURL: URL)
        case installing
        case failed(String)
    }

    @Published var state: State = .idle

    private let apiURL = URL(string: "https://api.github.com/repos/jayzzjay98-stack/HeyBar/releases/latest")!

    func resetToIdle() {
        state = .idle
    }

    func checkForUpdates() {
        state = .checking
        Task {
            do {
                let (latestVersion, downloadURL) = try await fetchLatestRelease()
                let current = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                if versionIsNewer(latestVersion, than: current) {
                    state = .available(version: latestVersion, downloadURL: downloadURL)
                } else {
                    state = .upToDate
                }
            } catch UpdateError.noRelease {
                state = .upToDate
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func startDownload(version: String, downloadURL: String) {
        guard let url = URL(string: downloadURL),
              url.scheme == "https",
              let host = url.host,
              host == "github.com" || host.hasSuffix(".githubusercontent.com") else {
            state = .failed("Untrusted download URL.")
            return
        }
        state = .downloading
        Task {
            do {
                let zipURL = try await download(from: url)
                state = .downloaded(version: version, zipURL: zipURL)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func installDownloaded(version: String, zipURL: URL) {
        state = .installing
        Task {
            do {
                try await installUpdate(from: zipURL)
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    // MARK: - Private

    private func fetchLatestRelease() async throws -> (version: String, downloadURL: String) {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw UpdateError.noRelease
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String else {
            throw UpdateError.parseError
        }

        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        let assets = json["assets"] as? [[String: Any]] ?? []
        guard let asset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
              let downloadURL = asset["browser_download_url"] as? String else {
            throw UpdateError.noAsset
        }

        return (version, downloadURL)
    }

    private func download(from url: URL) async throws -> URL {
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent("HeyBar-update.zip")
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tempURL, to: destURL)
        return destURL
    }

    private func installUpdate(from zipURL: URL) async throws {
        let workDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("HeyBar-update-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)

        try await run("/usr/bin/unzip", ["-q", "-o", zipURL.path, "-d", workDir.path])

        let items = try FileManager.default.contentsOfDirectory(
            at: workDir, includingPropertiesForKeys: [.isDirectoryKey]
        )
        guard let newAppURL = items.first(where: { $0.pathExtension == "app" }) else {
            throw UpdateError.noAppBundle
        }

        try? await run("/usr/bin/xattr", ["-rd", "com.apple.quarantine", newAppURL.path])
        try await run("/usr/bin/codesign", ["--force", "--deep", "--sign", "-", newAppURL.path])

        let installPath = Bundle.main.bundleURL.path
        let newPath = newAppURL.path
        let executableName = Bundle.main.executableURL?.lastPathComponent ?? "HeyBar"
        let installedExecutablePath = "\(installPath)/Contents/MacOS/\(executableName)"
        let stagedInstallPath = "\(installPath).updating"
        let backupInstallPath = "\(installPath).previous"

        let script = """
        #!/bin/bash
        sleep 1.5
        /usr/bin/pkill -x \(shellEscape(executableName)) 2>/dev/null
        /usr/bin/pkill -f \(shellEscape("/\(executableName).app/Contents/MacOS/\(executableName)")) 2>/dev/null
        for _ in {1..50}; do
          /usr/bin/pgrep -x \(shellEscape(executableName)) >/dev/null 2>&1 || break
          sleep 0.1
        done
        # Reset the TCC accessibility entry so the new binary is not rejected
        # by a stale code-signature from the previous installation.
        /usr/bin/tccutil reset Accessibility com.gravity.heybar 2>/dev/null
        rm -rf \(shellEscape(stagedInstallPath))
        rm -rf \(shellEscape(backupInstallPath))
        /usr/bin/ditto \(shellEscape(newPath)) \(shellEscape(stagedInstallPath))
        if [[ -d \(shellEscape(installPath)) ]]; then
          mv \(shellEscape(installPath)) \(shellEscape(backupInstallPath))
        fi
        mv \(shellEscape(stagedInstallPath)) \(shellEscape(installPath))
        rm -rf \(shellEscape(backupInstallPath))
        /usr/bin/codesign --force --deep --sign - \(shellEscape(installPath)) 2>/dev/null
        /usr/bin/nohup /usr/bin/env -u HEYBAR_SETTINGS_HELPER \(shellEscape(installedExecutablePath)) >/dev/null 2>&1 &
        """

        let scriptPath = workDir.appendingPathComponent("replace.sh").path
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: Int16(0o755))],
            ofItemAtPath: scriptPath
        )

        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = [scriptPath]
        try launcher.run()

        NSApp.terminate(nil)
    }

    private func run(_ executable: String, _ arguments: [String]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            let errorPipe = Pipe()
            process.standardOutput = Pipe()
            process.standardError = errorPipe

            process.terminationHandler = { p in
                if p.terminationStatus == 0 {
                    continuation.resume()
                } else {
                    let output = String(
                        data: errorPipe.fileHandleForReading.readDataToEndOfFile(),
                        encoding: .utf8
                    ) ?? ""
                    continuation.resume(throwing: UpdateError.processFailed(executable, output))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func shellEscape(_ s: String) -> String {
        "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private func versionIsNewer(_ new: String, than current: String) -> Bool {
        let parse: (String) -> [Int] = { v in v.split(separator: ".").compactMap { Int($0) } }
        let newParts = parse(new)
        let curParts = parse(current)
        for i in 0..<max(newParts.count, curParts.count) {
            let n = i < newParts.count ? newParts[i] : 0
            let c = i < curParts.count ? curParts[i] : 0
            if n > c { return true }
            if n < c { return false }
        }
        return false
    }
}

private enum UpdateError: LocalizedError {
    case noRelease
    case parseError
    case noAsset
    case noAppBundle
    case processFailed(String, String)

    var errorDescription: String? {
        switch self {
        case .noRelease:
            return "No release published yet."
        case .parseError:
            return "Could not read release information from GitHub."
        case .noAsset:
            return "Release does not include a download package."
        case .noAppBundle:
            return "Downloaded package did not contain an app."
        case .processFailed(_, let output):
            return output.isEmpty ? "Update step failed." : output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
