import UIKit
import UniformTypeIdentifiers

/// منتقي ملفات UIKit مباشر (أكثر ثباتاً من fileImporter) — ينسخ الملف إلى التطبيق
final class DocumentPicker: NSObject, UIDocumentPickerDelegate {
    static let shared = DocumentPicker()
    private var onPick: ((URL) -> Void)?

    func pick(_ onPick: @escaping (URL) -> Void) {
        self.onPick = onPick
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        topController()?.present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first { onPick?(url) }
    }

    private func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
