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
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    
                    if proxy.size.width > 960 {
                        HStack(alignment: .top, spacing: 20) {
                            leftColumn
                                .frame(maxWidth: .infinity, alignment: .top)
                            rightColumn
                                .frame(maxWidth: .infinity, alignment: .top)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            leftColumn
                            rightColumn
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: 1180)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(Theme.canvas.ignoresSafeArea())
        }
        .frame(
            minWidth: AppWindowMetrics.minContentWidth,
            minHeight: AppWindowMetrics.minContentHeight
        )
        .onAppear {
            intervalInput = String(settings.intervalMinutes)
            cacheInput = String(settings.cacheMaxMB)
            isFavorite = favStore.isFavorite(engine.currentImageURL)
        }
        .onChange(of: engine.currentImageURL) { _ in
            isFavorite = favStore.isFavorite(engine.currentImageURL)
        }
        .onChange(of: settings.intervalMinutes) { newValue in
            if String(newValue) != intervalInput {
                intervalInput = String(newValue)
            }
        }
        .onChange(of: settings.cacheMaxMB) { newValue in
            if String(newValue) != cacheInput {
                cacheInput = String(newValue)
            }
        }
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        capsuleLabel(LocalizedStrings.text(for: "workspaceBadge", language: settings.language))
                        capsuleLabel(engine.currentImageURL == nil ? LocalizedStrings.text(for: "statusSetup", language: settings.language) : LocalizedStrings.text(for: "statusReady", language: settings.language), tint: Theme.badgeBlueText, background: Theme.badgeBlueBackground)
                    }
                    
                    Text(LocalizedStrings.text(for: "heroTitle", language: settings.language))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.nearBlack)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(LocalizedStrings.text(for: "heroSubtitle", language: settings.language))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 16)
                
                Picker(LocalizedStrings.text(for: "language", language: settings.language), selection: $settings.language) {
                    ForEach(Language.allCases) { lang in
                        Text(languageLabel(for: lang)).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 140)
            }
            
            HStack(spacing: 12) {
                Button(LocalizedStrings.text(for: "changeNow", language: settings.language)) {
                    Task { await engine.changeNow() }
                }
                .buttonStyle(PrimaryActionButtonStyle())
            }
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                spacing: 12
            ) {
                metricCard(title: LocalizedStrings.text(for: "imageSource", language: settings.language), value: label(for: settings.provider))
                metricCard(title: LocalizedStrings.text(for: "autoChangeInterval", language: settings.language), value: "\(settings.intervalMinutes) \(LocalizedStrings.text(for: "minutesUnitShort", language: settings.language))")
                metricCard(title: LocalizedStrings.text(for: "cacheLimit", language: settings.language), value: "\(settings.cacheMaxMB) \(LocalizedStrings.text(for: "megabytesUnitShort", language: settings.language))")
                metricCard(title: LocalizedStrings.text(for: "lastChangeTime", language: settings.language), value: lastChangeSummary)
            }
        }
        .modifier(CardSurface(fill: Theme.surface))
    }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            previewSection
            activitySection
            librarySection
        }
    }
    
    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            automationSection
            sourceSection
            systemSection
        }
    }
    
    private var previewSection: some View {
        sectionCard(
            title: LocalizedStrings.text(for: "currentPreview", language: settings.language),
            description: LocalizedStrings.text(for: "previewHint", language: settings.language),
            fill: Theme.surface
        ) {
            if let url = engine.currentImageURL, let img = NSImage(contentsOf: url) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        capsuleLabel(LocalizedStrings.text(for: "statusReady", language: settings.language))
                        Spacer()
                        Button {
                            if let currentURL = engine.currentImageURL {
                                favStore.toggleFavorite(currentURL)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isFavorite = favStore.isFavorite(currentURL)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(isFavorite ? LocalizedStrings.text(for: "unfavorite", language: settings.language) : LocalizedStrings.text(for: "favorite", language: settings.language))
                            }
                        }
                        .buttonStyle(FavoriteActionButtonStyle(active: isFavorite))
                    }
                    
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .clipped()
                        .background(Theme.altSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStrings.text(for: "currentFile", language: settings.language))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.tertiaryText)
                            .textCase(.uppercase)
                        Text(url.lastPathComponent)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.secondaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    capsuleLabel(LocalizedStrings.text(for: "statusSetup", language: settings.language), tint: Theme.orange, background: Theme.altSurface)
                    
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.altSurface)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundStyle(Theme.tertiaryText)
                                Text(LocalizedStrings.text(for: "previewUnavailable", language: settings.language))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }
            }
        }
    }
    
    private var activitySection: some View {
        sectionCard(
            title: LocalizedStrings.text(for: "activitySection", language: settings.language),
            description: LocalizedStrings.text(for: "activityDescription", language: settings.language),
            fill: Theme.altSurface
        ) {
            VStack(alignment: .leading, spacing: 14) {
                statusRow(
                    title: LocalizedStrings.text(for: "lastChangeTime", language: settings.language),
                    value: lastChangeSummary,
                    accent: Theme.badgeBlueText
                )
                
                statusRow(
                    title: LocalizedStrings.text(for: "error", language: settings.language),
                    value: engine.lastError ?? LocalizedStrings.text(for: "noRecentErrors", language: settings.language),
                    accent: engine.lastError == nil ? Theme.teal : Theme.orange,
                    multiline: true
                )
            }
        }
    }
    
    private var librarySection: some View {
        sectionCard(
            title: LocalizedStrings.text(for: "librarySection", language: settings.language),
            description: LocalizedStrings.text(for: "libraryDescription", language: settings.language),
            fill: Theme.surface
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button(LocalizedStrings.text(for: "openCacheDir", language: settings.language)) {
                    openCacheDirectory()
                }
                .buttonStyle(SecondaryActionButtonStyle(expandToFill: true))
                .pointerHandCursor()
                
                Button(LocalizedStrings.text(for: "clearCache", language: settings.language)) {
                    clearCache()
                }
                .buttonStyle(GhostActionButtonStyle())
                .pointerHandCursor()
            }
        }
    }
    
    private var automationSection: some View {
        sectionCard(
            title: LocalizedStrings.text(for: "automationSection", language: settings.language),
            description: LocalizedStrings.text(for: "automationDescription", language: settings.language),
            fill: Theme.surface
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    labeledInput(
                        title: LocalizedStrings.text(for: "autoChangeInterval", language: settings.language),
                        placeholder: "240",
                        text: $intervalInput,
                        onChange: updateInterval
                    )
                    labeledInput(
                        title: LocalizedStrings.text(for: "cacheLimit", language: settings.language),
                        placeholder: "128",
                        text: $cacheInput,
                        onChange: updateCacheLimit
                    )
                }
                
                Divider()
                    .overlay(Theme.border)
                
                Toggle(LocalizedStrings.text(for: "changeOnWake", language: settings.language), isOn: $settings.changeOnWake)
                    .toggleStyle(.switch)
                    .foregroundStyle(Theme.nearBlack)
                Toggle(LocalizedStrings.text(for: "avoidDuplicates", language: settings.language), isOn: $settings.avoidDuplicates)
                    .toggleStyle(.switch)
                    .foregroundStyle(Theme.nearBlack)
            }
        }
    }
    
    private var sourceSection: some View {
        sectionCard(
            title: LocalizedStrings.text(for: "sourceSection", language: settings.language),
            description: LocalizedStrings.text(for: "sourceDescription", language: settings.language),
            fill: Theme.altSurface
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.text(for: "imageSource", language: settings.language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.tertiaryText)
                        .textCase(.uppercase)
                    Picker(LocalizedStrings.text(for: "imageSource", language: settings.language), selection: $settings.provider) {
                        ForEach(ProviderType.allCases) { provider in
                            Text(label(for: provider)).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if settings.provider == .unsplash || settings.provider == .auto {
                    VStack(alignment: .leading, spacing: 12) {
                        labeledTextField(
                            title: LocalizedStrings.text(for: "unsplashAccessKey", language: settings.language),
                            placeholder: LocalizedStrings.text(for: "optional", language: settings.language),
                            text: $settings.unsplashAccessKey
                        )
                        labeledTextField(
                            title: LocalizedStrings.text(for: "keywords", language: settings.language),
                            placeholder: LocalizedStrings.text(for: "keywordsPlaceholder", language: settings.language),
                            text: $settings.unsplashQuery
                        )
                    }
                }
            }
        }
    }
    
    private var systemSection: some View {
        sectionCard(
            title: LocalizedStrings.text(for: "systemSection", language: settings.language),
            description: LocalizedStrings.text(for: "systemDescription", language: settings.language),
            fill: Theme.surface
        ) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.text(for: "language", language: settings.language))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.tertiaryText)
                        .textCase(.uppercase)
                    Picker(LocalizedStrings.text(for: "language", language: settings.language), selection: $settings.language) {
                        ForEach(Language.allCases) { lang in
                            Text(languageLabel(for: lang)).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                    .overlay(Theme.border)
                
                Toggle(LocalizedStrings.text(for: "launchAtLogin", language: settings.language), isOn: $settings.launchAtLogin)
                    .toggleStyle(.switch)
                    .foregroundStyle(Theme.nearBlack)
                Toggle(LocalizedStrings.text(for: "showMenuBarIcon", language: settings.language), isOn: $settings.showMenuBarIcon)
                    .toggleStyle(.switch)
                    .foregroundStyle(Theme.nearBlack)
            }
        }
    }
    
    private var lastChangeSummary: String {
        if let date = engine.lastChange {
            return date.formatted(date: .abbreviated, time: .shortened)
        }
        return LocalizedStrings.text(for: "waitingForFirstChange", language: settings.language)
    }
    
    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
                .textCase(.uppercase)
                .lineLimit(3)
                .frame(height: 44, alignment: .topLeading)
            Text(value)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.nearBlack)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.altSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private func sectionCard<Content: View>(title: String, description: String, fill: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.nearBlack)
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            content()
        }
        .modifier(CardSurface(fill: fill))
    }
    
    private func statusRow(title: String, value: String, accent: Color, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.tertiaryText)
                    .textCase(.uppercase)
            }
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(multiline && engine.lastError != nil ? Theme.orange : Theme.nearBlack)
                .fixedSize(horizontal: false, vertical: multiline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
    
    private func labeledInput(title: String, placeholder: String, text: Binding<String>, onChange: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
                .textCase(.uppercase)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.nearBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
                .onChange(of: text.wrappedValue, perform: onChange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func labeledTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.tertiaryText)
                .textCase(.uppercase)
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.nearBlack)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func capsuleLabel(_ title: String, tint: Color = Theme.badgeBlueText, background: Color = Theme.badgeBlueBackground) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.2)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(background)
            )
    }
    
    private func updateInterval(_ value: String) {
        let filtered = value.filter(\.isNumber)
        if filtered != value {
            intervalInput = filtered
        }
        if let numericValue = Int(filtered), numericValue > 0 {
            settings.intervalMinutes = numericValue
        }
    }
    
    private func updateCacheLimit(_ value: String) {
        let filtered = value.filter(\.isNumber)
        if filtered != value {
            cacheInput = filtered
        }
        if let numericValue = Int(filtered), numericValue > 0 {
            settings.cacheMaxMB = numericValue
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

private enum Theme {
    static let canvas = Color.white
    static let surface = Color(hex: 0xFFFFFF)
    static let altSurface = Color(hex: 0xF6F5F4)
    static let nearBlack = Color(hex: 0x000000, opacity: 0.95)
    static let secondaryText = Color(hex: 0x615D59)
    static let tertiaryText = Color(hex: 0xA39E98)
    static let border = Color.black.opacity(0.1)
    static let accent = Color(hex: 0x0075DE)
    static let accentPressed = Color(hex: 0x005BAB)
    static let badgeBlueBackground = Color(hex: 0xF2F9FF)
    static let badgeBlueText = Color(hex: 0x097FE8)
    static let teal = Color(hex: 0x2A9D99)
    static let orange = Color(hex: 0xDD5B00)
}

private struct CardSurface: ViewModifier {
    let fill: Color
    
    func body(content: Content) -> some View {
        content
            .padding(22)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 18, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.027), radius: 8, x: 0, y: 2)
            .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.01), radius: 1, x: 0, y: 0.2)
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(configuration.isPressed ? Theme.accentPressed : Theme.accent)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .pointerHandCursor()
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    var expandToFill: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.nearBlack)
            .frame(maxWidth: expandToFill ? .infinity : nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.altSurface.opacity(configuration.isPressed ? 0.75 : 1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .pointerHandCursor()
    }
}

private struct GhostActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.7 : 0.001))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
            .pointerHandCursor()
    }
}

private struct FavoriteActionButtonStyle: ButtonStyle {
    let active: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(active ? Color.white : Theme.badgeBlueText)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                shape
                    .fill(active ? Theme.badgeBlueText : Theme.badgeBlueBackground)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                shape
                    .stroke(active ? Color.clear : Theme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .contentShape(shape)
            .onHover { inside in
                if inside {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            }
    }
}

private extension Color {
    init(hex: Int, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

private extension View {
    func pointerHandCursor() -> some View {
        onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
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
