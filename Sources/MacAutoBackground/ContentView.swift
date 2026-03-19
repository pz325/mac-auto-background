import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var engine: Engine
    private let favStore = RecentFavoritesStore()
    @State private var isFavorite: Bool = false
    @State private var intervalInput: String = ""
    @State private var cacheInput: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker(LocalizedStrings.text(for: "language", language: settings.language), selection: $settings.language) {
                ForEach(Language.allCases) { lang in
                    Text(languageLabel(for: lang)).tag(lang)
                }
            }
            HStack {
                Text(LocalizedStrings.text(for: "autoChangeInterval", language: settings.language))
                Spacer()
                TextField("240", text: $intervalInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100, alignment: .center)
                    .onAppear {
                        intervalInput = String(settings.intervalMinutes)
                    }
                    .onChange(of: intervalInput) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            intervalInput = filtered
                        }
                        if let value = Int(filtered), value > 0 {
                            settings.intervalMinutes = value
                        }
                    }
                    .onChange(of: settings.intervalMinutes) { newValue in
                        if String(newValue) != intervalInput {
                            intervalInput = String(newValue)
                        }
                    }
            }
            HStack {
                Text(LocalizedStrings.text(for: "cacheLimit", language: settings.language))
                Spacer()
                TextField("128", text: $cacheInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100, alignment: .center)
                    .onAppear {
                        cacheInput = String(settings.cacheMaxMB)
                    }
                    .onChange(of: cacheInput) { newValue in
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            cacheInput = filtered
                        }
                        if let value = Int(filtered), value > 0 {
                            settings.cacheMaxMB = value
                        }
                    }
                    .onChange(of: settings.cacheMaxMB) { newValue in
                        if String(newValue) != cacheInput {
                            cacheInput = String(newValue)
                        }
                    }
            }
            Toggle(LocalizedStrings.text(for: "changeOnWake", language: settings.language), isOn: $settings.changeOnWake)
            Toggle(LocalizedStrings.text(for: "avoidDuplicates", language: settings.language), isOn: $settings.avoidDuplicates)
            Toggle(LocalizedStrings.text(for: "launchAtLogin", language: settings.language), isOn: $settings.launchAtLogin)
            Toggle(LocalizedStrings.text(for: "showMenuBarIcon", language: settings.language), isOn: $settings.showMenuBarIcon)
            Picker(LocalizedStrings.text(for: "imageSource", language: settings.language), selection: $settings.provider) {
                ForEach(ProviderType.allCases) { p in
                    Text(label(for: p)).tag(p)
                }
            }
            if settings.provider == .unsplash || settings.provider == .auto {
                HStack {
                    Text(LocalizedStrings.text(for: "unsplashAccessKey", language: settings.language))
                    Spacer()
                    TextField(LocalizedStrings.text(for: "optional", language: settings.language), text: $settings.unsplashAccessKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 360)
                }
                HStack {
                    Text(LocalizedStrings.text(for: "keywords", language: settings.language))
                    Spacer()
                    TextField(LocalizedStrings.text(for: "keywordsPlaceholder", language: settings.language), text: $settings.unsplashQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 360)
                }
            }
            HStack(spacing: 12) {
                Button(LocalizedStrings.text(for: "changeNow", language: settings.language)) {
                    Task { await engine.changeNow() }
                }
                Button(LocalizedStrings.text(for: "testFetch", language: settings.language)) {
                    Task { await engine.changeNow() }
                }
            }
            HStack(spacing: 12) {
                Button(LocalizedStrings.text(for: "openCacheDir", language: settings.language)) {
                    openCacheDirectory()
                }
                Button(LocalizedStrings.text(for: "clearCache", language: settings.language)) {
                    clearCache()
                }
            }
            if let date = engine.lastChange {
                Text(LocalizedStrings.text(for: "lastChangeTime", language: settings.language) + "\(date.formatted(date: .abbreviated, time: .standard))")
                    .foregroundStyle(.secondary)
            }
            if let err = engine.lastError {
                Text(LocalizedStrings.text(for: "error", language: settings.language) + "\(err)").foregroundStyle(.red)
            }
            if let url = engine.currentImageURL, let img = NSImage(contentsOf: url) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStrings.text(for: "currentPreview", language: settings.language))
                            .font(.headline)
                        Spacer()
                        Button(isFavorite ? LocalizedStrings.text(for: "unfavorite", language: settings.language) : LocalizedStrings.text(for: "favorite", language: settings.language)) {
                            favStore.toggleFavorite(url)
                            isFavorite.toggle()
                        }
                        .buttonStyle(.bordered)
                    }
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2))
                        )
                    Text(url.lastPathComponent)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } else {
                Text(LocalizedStrings.text(for: "previewUnavailable", language: settings.language)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 740, minHeight: 700)
        .onAppear {
            isFavorite = favStore.isFavorite(engine.currentImageURL)
        }
        .onChange(of: engine.currentImageURL) { _ in
            isFavorite = favStore.isFavorite(engine.currentImageURL)
        }
    }
    
    private func label(for p: ProviderType) -> String {
        switch p {
        case .auto: return LocalizedStrings.text(for: "autoSource", language: settings.language)
        case .bing: return LocalizedStrings.text(for: "bingSource", language: settings.language)
        case .picsum: return LocalizedStrings.text(for: "picsumSource", language: settings.language)
        case .unsplash: return LocalizedStrings.text(for: "unsplashSource", language: settings.language)
        }
    }
    
    private func languageLabel(for lang: Language) -> String {
        switch lang {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
    
    private func openCacheDirectory() {
        do {
            let cacheURL = try ImagesDirectory.url()
            NSWorkspace.shared.open(cacheURL)
        } catch {
            print("无法打开缓存目录：\(error.localizedDescription)")
        }
    }
    
    private func clearCache() {
        let alert = NSAlert()
        alert.messageText = LocalizedStrings.text(for: "confirmClearCache", language: settings.language)
        alert.informativeText = LocalizedStrings.text(for: "confirmClearCacheMessage", language: settings.language)
        alert.alertStyle = .warning
        alert.addButton(withTitle: LocalizedStrings.text(for: "cancel", language: settings.language))
        alert.addButton(withTitle: LocalizedStrings.text(for: "clear", language: settings.language))
        
        let response = alert.runModal()
        
        if response == .alertSecondButtonReturn {
            do {
                let cacheURL = try ImagesDirectory.url()
                let fileManager = FileManager.default
                let files = try fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                
                for file in files {
                    try fileManager.removeItem(at: file)
                }
                
                print("已清除 \(files.count) 个缓存文件")
            } catch {
                print("清除缓存失败：\(error.localizedDescription)")
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppSettings())
            .environmentObject(Engine())
    }
}
#endif
