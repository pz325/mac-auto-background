import Foundation

enum LocalizedStrings {
    static func text(for key: String, language: Language) -> String {
        switch language {
        case .chinese:
            return chineseText[key] ?? key
        case .english:
            return englishText[key] ?? key
        }
    }
    
    private static let chineseText: [String: String] = [
        "autoChangeInterval": "自动更换间隔(分钟)",
        "cacheLimit": "图片缓存上限(MB)",
        "changeOnWake": "睡眠/合盖唤醒后更换",
        "avoidDuplicates": "避免重复图片",
        "launchAtLogin": "登录时自动启动",
        "showMenuBarIcon": "显示菜单栏图标",
        "imageSource": "图片来源",
        "autoSource": "自动选择（优先中国大陆可访问源）",
        "bingSource": "Bing 每日壁纸",
        "picsumSource": "Picsum 随机高清图",
        "unsplashSource": "Unsplash 随机图",
        "unsplashAccessKey": "Unsplash Access Key",
        "optional": "可选",
        "keywords": "关键词",
        "keywordsPlaceholder": "例如: nature, city",
        "changeNow": "立即更换",
        "testFetch": "测试获取图片",
        "openCacheDir": "打开缓存目录",
        "clearCache": "清除缓存",
        "lastChangeTime": "上次更换时间：",
        "error": "错误：",
        "currentPreview": "当前桌面预览",
        "unfavorite": "取消收藏",
        "favorite": "收藏当前",
        "previewUnavailable": "当前桌面预览不可用",
        "confirmClearCache": "确认清除缓存",
        "confirmClearCacheMessage": "确定要清除所有本地图片缓存吗？此操作不可撤销。",
        "cancel": "取消",
        "clear": "清除",
        "language": "语言",
        "chinese": "中文",
        "english": "English",
        "openWindow": "打开窗口",
        "favoriteCurrent": "收藏当前",
        "unfavoriteCurrent": "取消收藏当前",
        "recent": "最近",
        "favorites": "收藏",
        "launchAtLoginEnabled": "登录时自动启动 ✓",
        "launchAtLoginDisabled": "登录时自动启动",
        "showMenuBarIconEnabled": "显示菜单栏图标 ✓",
        "showMenuBarIconDisabled": "显示菜单栏图标",
        "quit": "退出"
    ]
    
    private static let englishText: [String: String] = [
        "autoChangeInterval": "Auto Change Interval (minutes)",
        "cacheLimit": "Cache Limit (MB)",
        "changeOnWake": "Change on Wake",
        "avoidDuplicates": "Avoid Duplicates",
        "launchAtLogin": "Launch at Login",
        "showMenuBarIcon": "Show Menu Bar Icon",
        "imageSource": "Image Source",
        "autoSource": "Auto (China-friendly)",
        "bingSource": "Bing Daily Wallpaper",
        "picsumSource": "Picsum Random",
        "unsplashSource": "Unsplash Random",
        "unsplashAccessKey": "Unsplash Access Key",
        "optional": "Optional",
        "keywords": "Keywords",
        "keywordsPlaceholder": "e.g., nature, city",
        "changeNow": "Change Now",
        "testFetch": "Test Fetch",
        "openCacheDir": "Open Cache Directory",
        "clearCache": "Clear Cache",
        "lastChangeTime": "Last changed: ",
        "error": "Error: ",
        "currentPreview": "Current Desktop Preview",
        "unfavorite": "Unfavorite",
        "favorite": "Favorite",
        "previewUnavailable": "Preview unavailable",
        "confirmClearCache": "Confirm Clear Cache",
        "confirmClearCacheMessage": "Are you sure you want to clear all cached images? This action cannot be undone.",
        "cancel": "Cancel",
        "clear": "Clear",
        "language": "Language",
        "chinese": "中文",
        "english": "English",
        "openWindow": "Open Window",
        "favoriteCurrent": "Favorite Current",
        "unfavoriteCurrent": "Unfavorite Current",
        "recent": "Recent",
        "favorites": "Favorites",
        "launchAtLoginEnabled": "Launch at Login ✓",
        "launchAtLoginDisabled": "Launch at Login",
        "showMenuBarIconEnabled": "Show Menu Bar Icon ✓",
        "showMenuBarIconDisabled": "Show Menu Bar Icon",
        "quit": "Quit"
    ]
}
