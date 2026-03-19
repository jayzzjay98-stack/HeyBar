import Foundation

@MainActor
final class UnsupportedFeatureController: ObservableObject {
    let title: String
    let message: String

    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}
