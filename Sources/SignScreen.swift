import SwiftUI

struct SignScreen: View {
    @State private var status = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                Text("وقّع ملف IPA من جهازك")
                    .font(.title3.bold())
                Button(action: pickIPA) {
                    Text("اختر ملف IPA")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
                if !status.isEmpty {
                    Text(status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                Spacer()
            }
            .padding(.top, 60)
            .navigationTitle("التوقيع")
        }
        .navigationViewStyle(.stack)
    }

    func pickIPA() {
        DocumentPicker.shared.pick { url in
            DispatchQueue.main.async { status = "جاري توقيع الملف..." }
            IPASigner.shared.signLocalIPA(at: url) { path in
                DispatchQueue.main.async {
                    if let path = path {
                        status = "تم التوقيع! جاري التثبيت..."
                        IPASigner.shared.installOTA(ipaURL: path)
                    } else {
                        status = "فشل توقيع الملف. تحقق من الشهادة."
                    }
                }
            }
        }
    }
}
