import SwiftUI
import UniformTypeIdentifiers

let sourceURL = "https://raw.githubusercontent.com/AbdTench/SwiftSource/refs/heads/main/My%20Source"

struct AppSource: Decodable {
    let apps: [AppItem]
}

struct AppItem: Identifiable, Decodable {
    var id = UUID()
    let name: String
    let subtitle: String?
    let iconURL: String?
    let downloadURL: String
    let version: String?
    let tintColor: String?

    enum CodingKeys: String, CodingKey {
        case name, subtitle, iconURL, downloadURL, version, tintColor
    }
}

extension Color {
    init(hex: String?) {
        let h = (hex ?? "007AFF").trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(red: Double((v >> 16) & 255) / 255,
                  green: Double((v >> 8) & 255) / 255,
                  blue: Double(v & 255) / 255)
    }
}

struct AppIcon: View {
    let url: String?
    let size: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: url ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Color.gray.opacity(0.25)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.225, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
        )
    }
}

struct GetButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("تثبيت")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 7)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct AppRow: View {
    let app: AppItem
    let action: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            AppIcon(url: app.iconURL, size: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(app.subtitle ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            GetButton(action: action)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

struct FeaturedCard: View {
    let app: AppItem
    let action: () -> Void

    var body: some View {
        let tint = Color(hex: app.tintColor)
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [tint, tint.opacity(0.55)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 6) {
                Text("تطبيق اليوم")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))
                Text(app.name)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text(app.subtitle ?? "")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                HStack {
                    AppIcon(url: app.iconURL, size: 52)
                    Text(app.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: action) {
                        Text("تثبيت")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 7)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(18)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct StatusBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
    }
}

struct StoreView: View {
    @State private var apps: [AppItem] = []
    @State private var query = ""
    @State private var status = ""

    var filtered: [AppItem] {
        query.isEmpty ? apps : apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !status.isEmpty { StatusBanner(text: status) }

                    if query.isEmpty, let first = apps.first {
                        FeaturedCard(app: first) { install(first) }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("أفضل التطبيقات")
                            .font(.title2.bold())
                            .padding(.horizontal)
                            .padding(.bottom, 6)
                        ForEach(filtered) { app in
                            AppRow(app: app) { install(app) }
                            Divider().padding(.leading, 92)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("i Cerf")
            .searchable(text: $query, prompt: "ابحث عن تطبيق")
            .refreshable { await load() }
            .task { await load() }
        }
        .navigationViewStyle(.stack)
    }

    func load() async {
        guard let url = URL(string: sourceURL) else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            apps = try JSONDecoder().decode(AppSource.self, from: data).apps
            status = ""
        } catch {
            status = "تعذر تحميل المصدر: \(error.localizedDescription)"
        }
    }

    func install(_ app: AppItem) {
        guard let url = URL(string: app.downloadURL) else { return }
        status = "جاري تحميل وتوقيع \(app.name)..."
        IPASigner.shared.downloadAndSign(from: url) { result in
            DispatchQueue.main.async {
                if let path = result {
                    status = "تم التوقيع! جاري التثبيت..."
                    IPASigner.shared.installOTA(ipaURL: path)
                } else {
                    status = "فشل التوقيع! تحقق من الشهادة."
                }
            }
        }
    }
}
