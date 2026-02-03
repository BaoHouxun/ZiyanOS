import QtQuick
import QtQuick.Controls
import QtQuick.Window
import ZiyanOS.SettingsManager
import ZiyanOS.SystemUtils

ApplicationWindow {
    id: desktop
    width: Screen.width
    height: Screen.height
    visible: false  // 改为false，由WindowManager控制显示
    flags: Qt.FramelessWindowHint
    title: "字研OS 桌面"

    // 关键修改：添加一个属性来标记是否允许关闭
    property bool allowClose: false

    // 窗口管理器引用
    property var windowManager: null

    // 添加SystemUtils
    SystemUtils {
        id: systemUtils
    }

    // 添加设置管理器
    SettingsManager {
        id: settingsManager
        onDesktopBackgroundChanged: function(background) {  // 添加参数声明
            console.log("桌面背景改变:", background)
            desktopBackground = background
        }
        onDesktopWallpaperChanged: function(wallpaper) {  // 添加参数声明
            console.log("桌面壁纸改变:", wallpaper)
            desktopWallpaper = wallpaper
        }
        // 添加窗口设置变化的处理
        onWindowTitleBarModeChanged: function(mode) {  // 添加参数声明
            console.log("窗口模式改变:", mode)
            // 更新所有已打开的窗口
            updateWindowSettings()
        }
        onWindowTitleBarColorChanged: function(color) {  // 添加参数声明
            console.log("窗口颜色改变:", color)
            // 更新所有已打开的窗口
            updateWindowSettings()
        }
    }

    // 壁纸属性 - 从设置管理器获取
    property string desktopBackground: settingsManager.desktopBackground
    property string desktopWallpaper: settingsManager.desktopWallpaper

    // 存储打开的窗口
    property var openWindows: []

    // 桌面背景
    Rectangle {
        anchors.fill: parent
        color: desktopWallpaper === "" ? desktopBackground : "transparent"

        // 如果设置了壁纸图片，显示图片
        Image {
            anchors.fill: parent
            source: desktopWallpaper
            fillMode: Image.PreserveAspectCrop
            visible: desktopWallpaper !== ""
        }

        // 桌面图标区域 - GridView 布局实现竖向排列和自动换列
        GridView {
            id: desktopIcons
            anchors {
                top: parent.top
                topMargin: 30
                left: parent.left
                leftMargin: 30
                right: parent.right
                bottom: parent.bottom
            }

            // 设置竖向排列（从上到下）
            flow: GridView.FlowTopToBottom
            // 设置单元格大小
            cellWidth: 100
            cellHeight: 100
            // 布局方向从左到右
            layoutDirection: Qt.LeftToRight
            // 禁用拖动
            interactive: false

            // 桌面图标委托
            delegate: Item {
                width: desktopIcons.cellWidth
                height: desktopIcons.cellHeight

                DesktopIcon {
                    iconText: model.iconText || "🌐"
                    iconName: model.iconName || "应用"
                    anchors.centerIn: parent

                    onClicked: {
                        createApplicationWindow(model.appType || "")
                    }
                    // 移除右键菜单相关代码
                }
            }

            model: ListModel {
                id: desktopIconsModel
            }

            Component.onCompleted: {
                // 只添加系统应用，移除应用安装器
                var systemApps = [
                    {
                        iconText: "🌐",
                        iconName: "浏览器",
                        appType: "browser",
                        appId: "browser"
                    },
                    {
                        iconText: "📁",
                        iconName: "文件浏览器",
                        appType: "filebrowser",
                        appId: "filebrowser"
                    },
                    {
                        iconText: "🧮",
                        iconName: "计算器",
                        appType: "calculator",
                        appId: "calculator"
                    },
                    {
                        iconText: "📝",
                        iconName: "文本编辑器",
                        appType: "texteditor",
                        appId: "texteditor"
                    },
                    {
                        iconText: "🖼️",
                        iconName: "图片查看器",
                        appType: "imageviewer",
                        appId: "imageviewer"
                    },
                    {
                        iconText: "🎵",
                        iconName: "音乐播放器",
                        appType: "musicplayer",
                        appId: "musicplayer"
                    },
                    {
                        iconText: "🎬",
                        iconName: "视频播放器",
                        appType: "videoplayer",
                        appId: "videoplayer"
                    },
                    {
                            iconText: "⬇️",
                            iconName: "下载管理器",
                            appType: "downloadmanager",
                            appId: "downloadmanager"
                    },
                    {
                        iconText: "⚙️",
                        iconName: "设置",
                        appType: "settings",
                        appId: "settings"
                    }
                ]

                for (var i = 0; i < systemApps.length; i++) {
                    desktopIconsModel.append(systemApps[i])
                }
            }
        }

        // 打开的窗口容器
        Item {
            id: windowsContainer
            anchors.fill: parent
        }
    }

    // 任务栏
    Rectangle {
        id: taskbar
        width: parent.width
        height: 50
        anchors.bottom: parent.bottom
        color: "#2c3e50"
        opacity: 0.9

        // 任务栏左侧 - 打开的应用
        Row {
            id: taskbarApps
            spacing: 5
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
        }

        // 任务栏右侧 - 日期、时间、锁屏和电源
        Row {
            spacing: 15
            anchors {
                right: parent.right
                rightMargin: 15
                verticalCenter: parent.verticalCenter
            }

            // 日期和时间显示
            Column {
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                // 日期显示
                Text {
                    id: dateText
                    color: "white"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }

                // 时间显示
                Text {
                    id: timeText
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }
            }

            // 锁屏按钮（新增）- 放在电源按钮左边
            Rectangle {
                width: 36
                height: 36
                radius: 4
                color: "transparent"
                border.color: "transparent"

                // 鼠标悬停时的背景
                Rectangle {
                    id: lockScreenHoverBg
                    anchors.fill: parent
                    radius: parent.radius
                    color: "#7f8c8d"
                    opacity: 0

                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }
                }

                Text {
                    text: "🔒"
                    color: "white"
                    font.pixelSize: 18
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: {
                        lockScreenHoverBg.opacity = 1
                    }
                    onExited: {
                        lockScreenHoverBg.opacity = 0
                    }
                    onClicked: {
                        console.log("点击锁屏按钮")
                        if (desktop.windowManager && desktop.windowManager.switchToLockScreen) {
                            desktop.windowManager.switchToLockScreen()
                        }
                    }
                }
            }

            // 电源按钮
            Rectangle {
                width: 36
                height: 36
                radius: 4
                color: "transparent"

                Text {
                    text: "🔌"
                    color: "white"
                    font.pixelSize: 18
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = "#e74c3c"
                    onExited: parent.color = "transparent"
                    onClicked: {
                        createApplicationWindow("power")
                    }
                }
            }
        }
    }

    // 修改壁纸改变的处理函数
    function handleWallpaperChanged(background, wallpaperPath) {
        console.log("壁纸改变:", background, wallpaperPath)
        // 更新设置管理器 - 直接赋值
        settingsManager.desktopBackground = background
        settingsManager.desktopWallpaper = wallpaperPath
        settingsManager.saveSettings()

        // 桌面属性会自动通过信号更新
    }

    // 组件定义
    Component {
        id: textEditorWindowComponent
        TextEditor {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: powerWindowComponent
        PowerWindow {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: browserWindowComponent
        BrowserWindow {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: fileBrowserWindowComponent
        FileBrowserWindow {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: calculatorWindowComponent
        CalculatorWindow {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: imageViewerWindowComponent
        ImageViewer {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: musicPlayerWindowComponent
        MusicPlayer {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: videoPlayerWindowComponent
        VideoPlayer {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
        id: downloadManagerWindowComponent
        DownloadManagerWindow {
            onWindowClosing: {
                removeWindow(this)
            }
        }
    }

    Component {
            id: settingsWindowComponent
            SettingsWindow {
                onWindowClosing: {
                    removeWindow(this)
                }
                onWallpaperChanged: (background, wallpaperPath) => {
                    // 使用新的处理函数
                    desktop.handleWallpaperChanged(background, wallpaperPath)
                }
            }
        }

        // 新增：彩蛋窗口组件
        Component {
            id: easterEggWindowComponent
            EasterEggWindow {
                onWindowClosing: {
                    removeWindow(this)
                }
            }
        }

    // 获取应用图标
    function getAppIcon(appType) {
        switch(appType) {
            case "browser": return "🌐"
            case "filebrowser": return "📁"
            case "calculator": return "🧮"
            case "texteditor": return "📝"
            case "imageviewer": return "🖼️"
            case "musicplayer": return "🎵"
            case "videoplayer": return "🎬"
            case "downloadmanager": return "⬇️"
            case "settings": return "⚙️"
            case "power": return "🔌"
            case "easteregg": return "🥚"
            default: return "📄"
        }
    }

    // 更新日期和时间
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var currentTime = new Date()
            // 更新日期显示
            dateText.text = currentTime.toLocaleDateString(Qt.locale(), "yyyy-MM-dd dddd")
            // 更新时间显示
            timeText.text = currentTime.toLocaleTimeString(Qt.locale(), "hh:mm:ss")
        }
    }

    // 创建应用窗口
    function createApplicationWindow(type, additionalParam) {
        var window
        var windowId = type + "_" + Date.now()
        var appIcon = getAppIcon(type)

        switch(type) {
            case "power":
                window = powerWindowComponent.createObject(desktop)
                // 关键：连接 requestDesktopClose 信号
                window.requestDesktopClose.connect(function() {
                    console.log("收到关闭桌面请求，设置允许关闭并退出应用")
                    // 设置允许关闭
                    allowClose = true
                    // 立即退出应用
                    Qt.quit()
                })
                break
            case "browser":
                // 处理参数：可能是字符串或对象
                var initialUrl = ""
                var isLocalFile = false

                if (typeof additionalParam === 'object' && additionalParam !== null) {
                    // 如果是对象，提取url和isLocalFile
                    initialUrl = additionalParam.url || ""
                    isLocalFile = additionalParam.isLocalFile || false
                } else {
                    // 如果是字符串，直接作为URL
                    initialUrl = additionalParam || ""
                }

                window = browserWindowComponent.createObject(desktop, {
                    "initialUrl": initialUrl,
                    "isLocalFile": isLocalFile,
                    "desktop": desktop,
                    "settingsManager": settingsManager  // 新增：传递设置管理器
                })
                break
            case "filebrowser":
                window = fileBrowserWindowComponent.createObject(desktop)
                break
            case "calculator":
                window = calculatorWindowComponent.createObject(desktop)
                break
            case "texteditor":
                window = textEditorWindowComponent.createObject(desktop)
                if (additionalParam && window.openFile) {
                    Qt.callLater(function() {
                        window.openFile(additionalParam)
                    })
                }
                break
            case "imageviewer":
                window = imageViewerWindowComponent.createObject(desktop)
                if (additionalParam && window.openImage) {
                    Qt.callLater(function() {
                        window.openImage(additionalParam)
                    })
                }
                break
            case "musicplayer":
                window = musicPlayerWindowComponent.createObject(desktop)
                if (additionalParam && window.openMusic) {
                    Qt.callLater(function() {
                        window.openMusic(additionalParam)
                    })
                }
                break
            case "settings":
                window = settingsWindowComponent.createObject(desktop)
                window.currentBackground = desktopBackground
                window.currentWallpaper = desktopWallpaper
                break
            case "videoplayer":
                window = videoPlayerWindowComponent.createObject(desktop)
                if (additionalParam && window.openVideo) {
                    Qt.callLater(function() {
                        window.openVideo(additionalParam)
                    })
                }
                break
            case "downloadmanager":
                // 处理参数：可能是字符串或对象
                var downloadUrl = ""
                if (additionalParam) {
                    if (typeof additionalParam === 'object' && additionalParam !== null) {
                        // 如果是对象，提取url属性
                        downloadUrl = additionalParam.url || ""
                    } else {
                        // 如果是字符串，直接作为URL
                        downloadUrl = additionalParam
                    }
                }

                // 创建窗口时传递initialUrl属性
                window = downloadManagerWindowComponent.createObject(desktop, {
                    "initialUrl": downloadUrl
                })
                break
            case "easteregg":  // 新增：彩蛋应用
                window = easterEggWindowComponent.createObject(desktop)
                break
            default:
                console.log("未知的窗口类型: " + type)
                return
        }

        if (window) {
            // 关键：传递设置管理器给窗口
            if (window.settingsManager !== undefined) {
                window.settingsManager = settingsManager
            }

            // 传递全局窗口设置
            if (window.globalWindowMode !== undefined) {
                window.globalWindowMode = settingsManager.windowTitleBarMode || "auto"
                window.globalWindowColor = settingsManager.windowTitleBarColor || "#3498db"
            }
            window.showWindow()
            openWindows.push({
                "window": window,
                "id": windowId,
                "type": type,
                "title": window.windowTitle,
                "icon": appIcon  // 存储图标
            })
            updateTaskbar()
        }
    }

    // 新增：更新所有窗口的设置
    function updateWindowSettings() {
        for (var i = 0; i < openWindows.length; i++) {
            var window = openWindows[i].window
            if (window && window.globalWindowMode !== undefined) {
                window.globalWindowMode = settingsManager.windowTitleBarMode
                window.globalWindowColor = settingsManager.windowTitleBarColor

                // 如果窗口有settingsManager属性，也更新它
                if (window.settingsManager !== undefined) {
                    window.settingsManager = settingsManager
                }
            }
        }
    }

    // 更新任务栏
    function updateTaskbar() {
        // 清空任务栏
        for (var i = taskbarApps.children.length - 1; i >= 0; i--) {
            taskbarApps.children[i].destroy()
        }

        // 重新添加应用按钮
        for (var j = 0; j < openWindows.length; j++) {
            var windowInfo = openWindows[j]
            var taskbarButton = taskbarButtonComponent.createObject(taskbarApps, {
                "windowTitle": windowInfo.title,
                "windowIndex": j,
                "windowIcon": windowInfo.icon  // 传递图标
            })
        }
    }

    // 移除窗口
    function removeWindow(window) {
        for (var i = 0; i < openWindows.length; i++) {
            if (openWindows[i].window === window) {
                openWindows.splice(i, 1)
                updateTaskbar()
                break
            }
        }
    }

    // 切换到窗口
    function activateWindow(index) {
        if (index >= 0 && index < openWindows.length) {
            var window = openWindows[index].window
            window.requestActivate()
            window.raise()
        }
    }

    // 任务栏按钮组件 - 修改后加入图标显示
    Component {
        id: taskbarButtonComponent

        Rectangle {
            id: taskbarButton
            width: 120
            height: 30
            color: "transparent"
            radius: 4

            property string windowTitle: ""
            property int windowIndex: -1
            property string windowIcon: "📄"  // 默认图标

            // 整个可点击区域（包括图标和标题）
            Rectangle {
                id: titleArea
                width: parent.width - 25  // 减去关闭按钮宽度
                height: parent.height
                color: "transparent"

                // 图标区域 - 显示在左侧
                Rectangle {
                    id: iconArea
                    width: 24
                    height: 24
                    color: "transparent"
                    anchors {
                        left: parent.left
                        leftMargin: 5
                        verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: windowIcon
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }
                }

                // 应用标题区域 - 在图标右侧
                Rectangle {
                    id: textArea
                    width: parent.width - iconArea.width - 10  // 减去图标宽度和边距
                    height: parent.height
                    anchors {
                        left: iconArea.right
                        leftMargin: 5
                    }
                    color: "transparent"

                    Text {
                        text: windowTitle
                        color: "white"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: 5
                        }
                    }
                }

                // 标题区域的点击事件 - 切换窗口最小化/恢复状态
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var windowInfo = desktop.openWindows[windowIndex]
                        if (windowInfo.window.isMinimized) {
                            // 如果窗口已最小化，则恢复它
                            windowInfo.window.restoreWindow()
                        } else {
                            // 如果窗口未最小化，则最小化它
                            windowInfo.window.minimizeWindow()
                        }
                    }
                    onEntered: {
                        // 鼠标悬停时改变背景色
                        titleArea.color = "#34495e"
                    }
                    onExited: {
                        titleArea.color = "transparent"
                    }
                }
            }

            // 关闭按钮 - 单独的区域，避免事件冲突
            Rectangle {
                id: closeBtn
                width: 25
                height: 25
                color: "transparent"
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 16
                    height: 16
                    color: "transparent"
                    anchors.centerIn: parent

                    Text {
                        text: "×"
                        color: "white"
                        font.pixelSize: 12
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    // 关闭按钮的点击事件 - 独立处理
                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.log("关闭任务栏窗口，索引:", windowIndex)
                            if (windowIndex >= 0 && windowIndex < desktop.openWindows.length) {
                                var window = desktop.openWindows[windowIndex].window
                                console.log("关闭窗口:", window.windowTitle)
                                window.close() // 直接关闭窗口
                            }
                        }
                        onEntered: {
                            parent.color = "#e74c3c"
                        }
                        onExited: {
                            parent.color = "transparent"
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // 初始化日期和时间
        var currentTime = new Date()
        dateText.text = currentTime.toLocaleDateString(Qt.locale(), "yyyy-MM-dd dddd")
        timeText.text = currentTime.toLocaleTimeString(Qt.locale(), "hh:mm:ss")

        // 加载壁纸设置
        console.log("加载持久化壁纸设置")
        settingsManager.loadSettings()

        // 移除鼠标覆盖程序的相关代码，现在在main.cpp中处理
        // if (systemUtils.hasPecmdIni()) {
        //     console.log("检测到pecmd.ini（PE环境），启动鼠标覆盖程序")
        //     mouseOverlayManager.startMouseOverlay()
        // } else {
        //     console.log("未检测到pecmd.ini（实体机环境），不启动鼠标覆盖程序")
        // }

        // 监听窗口设置变化
        settingsManager.windowTitleBarModeChanged.connect(function(mode) {
            console.log("窗口模式改变:", mode)
            // 更新所有已打开的窗口
            updateWindowSettings()
        })

        settingsManager.windowTitleBarColorChanged.connect(function(color) {
            console.log("窗口颜色改变:", color)
            // 更新所有已打开的窗口
            updateWindowSettings()
        })

        // 显示窗口
        visible = true
        raise()
        requestActivate()
    }

    onClosing: (close) => {
        console.log("Desktop window closing event triggered, allowClose:", allowClose)

        // 移除鼠标覆盖程序的停止代码，现在在main.cpp中处理
        // if (mouseOverlayManager.isRunning) {
        //     mouseOverlayManager.stopMouseOverlay()
        // }

        // 如果不允许关闭，阻止并弹出关机窗口
        if (!allowClose) {
            close.accepted = false

            // 检查是否已经有关机窗口
            var hasPowerWindow = false
            for (var i = 0; i < openWindows.length; i++) {
                if (openWindows[i].type === "power") {
                    hasPowerWindow = true
                    // 将已有的关机窗口提到最前面
                    openWindows[i].window.raise()
                    openWindows[i].window.requestActivate()
                    break
                }
            }

            // 如果没有关机窗口，创建一个新的
            if (!hasPowerWindow) {
                console.log("Alt+F4 pressed, showing power window. Has power window:", hasPowerWindow)
                createApplicationWindow("power")
            }
        } else {
            // 如果允许关闭，接受关闭事件
            close.accepted = true
            console.log("允许关闭桌面应用")
        }
    }
}
