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
            HStack {
                Text("自动更换间隔(分钟)")
                Spacer()
                TextField("60", text: $intervalInput)
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
                Text("图片缓存上限(MB)")
                Spacer()
                TextField("512", text: $cacheInput)
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
            Toggle("睡眠/合盖唤醒后更换", isOn: $settings.changeOnWake)
            Toggle("避免重复图片", isOn: $settings.avoidDuplicates)
            Toggle("登录时自动启动", isOn: $settings.launchAtLogin)
            Toggle("显示菜单栏图标", isOn: $settings.showMenuBarIcon)
            Picker("图片来源", selection: $settings.provider) {
                ForEach(ProviderType.allCases) { p in
                    Text(label(for: p)).tag(p)
                }
            }
            if settings.provider == .unsplash || settings.provider == .auto {
                HStack {
                    Text("Unsplash Access Key")
                    Spacer()
                    TextField("可选", text: $settings.unsplashAccessKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 360)
                }
                HStack {
                    Text("关键词")
                    Spacer()
                    TextField("例如: nature, city", text: $settings.unsplashQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 360)
                }
            }
            HStack(spacing: 12) {
                Button("立即更换") {
                    Task { await engine.changeNow() }
                }
                Button("测试获取图片") {
                    Task { await engine.changeNow() }
                }
            }
            HStack(spacing: 12) {
                Button("打开缓存目录") {
                    openCacheDirectory()
                }
                Button("清除缓存") {
                    clearCache()
                }
            }
            if let date = engine.lastChange {
                Text("上次更换时间：\(date.formatted(date: .abbreviated, time: .standard))")
                    .foregroundStyle(.secondary)
            }
            if let err = engine.lastError {
                Text("错误：\(err)").foregroundStyle(.red)
            }
            if let url = engine.currentImageURL, let img = NSImage(contentsOf: url) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("当前桌面预览")
                            .font(.headline)
                        Spacer()
                        Button(isFavorite ? "取消收藏" : "收藏当前") {
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
                Text("当前桌面预览不可用").foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 740, minHeight: 600)
        .onAppear {
            isFavorite = favStore.isFavorite(engine.currentImageURL)
        }
        .onChange(of: engine.currentImageURL) { _ in
            isFavorite = favStore.isFavorite(engine.currentImageURL)
        }
    }
    
    private func label(for p: ProviderType) -> String {
        switch p {
        case .auto: return "自动选择（优先中国大陆可访问源）"
        case .bing: return "Bing 每日壁纸"
        case .picsum: return "Picsum 随机高清图"
        case .unsplash: return "Unsplash 随机图"
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
        alert.messageText = "确认清除缓存"
        alert.informativeText = "确定要清除所有本地图片缓存吗？此操作不可撤销。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "取消")
        alert.addButton(withTitle: "清除")
        
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
