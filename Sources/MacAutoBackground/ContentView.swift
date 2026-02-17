import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var engine: Engine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("自动更换间隔(分钟)")
                Spacer()
                Stepper(value: $settings.intervalMinutes, in: 1...1440, step: 1) {
                    Text("\(settings.intervalMinutes)")
                        .frame(width: 60, alignment: .trailing)
                }
                .labelsHidden()
            }
            HStack {
                Text("图片缓存上限(MB)")
                Spacer()
                Stepper(value: $settings.cacheMaxMB, in: 64...4096, step: 64) {
                    Text("\(settings.cacheMaxMB)")
                        .frame(width: 60, alignment: .trailing)
                }
                .labelsHidden()
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
            HStack(spacing: 12) {
                Button("立即更换") {
                    Task { await engine.changeNow() }
                }
                Button("测试获取图片") {
                    Task { await engine.changeNow() }
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
                    Text("当前桌面预览")
                        .font(.headline)
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
        .frame(minWidth: 560, minHeight: 420)
    }
    
    private func label(for p: ProviderType) -> String {
        switch p {
        case .picsum: return "Picsum 随机高清图"
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
