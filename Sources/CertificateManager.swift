import SwiftUI
import UniformTypeIdentifiers

struct CertificateView: View {
    @AppStorage("p12Password") private var p12Password = ""
    @State private var p12FileName = UserDefaults.standard.string(forKey: "p12FileName") ?? "لم يتم الاختيار"
    @State private var provFileName = UserDefaults.standard.string(forKey: "provFileName") ?? "لم يتم الاختيار"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ملف الشهادة (.p12)")) {
                    HStack {
                        Text(p12FileName).foregroundColor(.secondary)
                        Spacer()
                        Button("اختيار") { pick("p12") }
                            .buttonStyle(.borderless)
                    }
                }

                Section(header: Text("ملف التخصيص (.mobileprovision)")) {
                    HStack {
                        Text(provFileName).foregroundColor(.secondary)
                        Spacer()
                        Button("اختيار") { pick("mobileprovision") }
                            .buttonStyle(.borderless)
                    }
                }

                Section(header: Text("كلمة سر الشهادة (إن وجدت)")) {
                    SecureField("أدخل الرمز هنا", text: $p12Password)
                }
            }
            .navigationTitle("الشهادات")
        }
        .navigationViewStyle(.stack)
    }

    func pick(_ type: String) {
        DocumentPicker.shared.pick { url in
            DispatchQueue.main.async { saveFile(url: url, type: type) }
        }
    }

    func saveFile(url: URL, type: String) {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent("cert.\(type)")

        try? FileManager.default.removeItem(at: dest)
        try? FileManager.default.copyItem(at: url, to: dest)

        if type == "p12" {
            p12FileName = url.lastPathComponent
            UserDefaults.standard.set(p12FileName, forKey: "p12FileName")
        } else {
            provFileName = url.lastPathComponent
            UserDefaults.standard.set(provFileName, forKey: "provFileName")
        }
    }
}
