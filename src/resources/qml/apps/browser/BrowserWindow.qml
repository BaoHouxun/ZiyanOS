import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtWebEngine

ZiyanWindow {
    id: browserWindow
    width: 1000
    height: 700
    windowTitle: "浏览器"

    // 设置管理器引用
    property var settingsManager: null
    // 引用桌面对象
    property var desktop: null
    // 属性：初始URL，如果为空则显示欢迎页面
    property string initialUrl: ""
    // 属性：是否将初始URL视为本地文件
    property bool isLocalFile: false
    // 存储当前加载的URL，用于在失败时保持地址栏显示
    property string currentUrl: ""
    // 当前显示模式：web（网页）、welcome（欢迎页面）、error（错误页面）
    property string currentMode: "web"

    // 错误页面相关属性
    property string lastError: ""
    property string lastFailedUrl: ""

    // 使用 contentItem 属性来设置窗口内容
    contentItem: Item {
        anchors.fill: parent

        Rectangle {
            id: toolbar
            width: parent.width
            height: 45
            anchors.top: parent.top
            color: "#ffffff"
            z: 100

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10

                // 后退按钮
                Rectangle {
                    width: 40
                    height: 30
                    color: webView.canGoBack && browserWindow.currentMode === "web" ? "#3498db" : "#bdc3c7"
                    radius: 4

                    Text {
                        text: "←"
                        color: "white"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: webView.canGoBack && browserWindow.currentMode === "web"
                        onClicked: {
                            console.log("后退")
                            webView.goBack()
                        }
                    }
                }

                // 前进按钮
                Rectangle {
                    width: 40
                    height: 30
                    color: webView.canGoForward && browserWindow.currentMode === "web" ? "#3498db" : "#bdc3c7"
                    radius: 4

                    Text {
                        text: "→"
                        color: "white"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: webView.canGoForward && browserWindow.currentMode === "web"
                        onClicked: {
                            console.log("前进")
                            webView.goForward()
                        }
                    }
                }

                // 刷新按钮 - 根据当前模式调整行为
                Rectangle {
                    width: 40
                    height: 30
                    color: browserWindow.currentMode === "web" ? "#3498db" : "#f39c12"
                    radius: 4

                    Text {
                        text: browserWindow.currentMode === "error" ? "↻" : "↻"
                        color: "white"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (browserWindow.currentMode === "web") {
                                console.log("刷新网页")
                                webView.reload()
                            } else if (browserWindow.currentMode === "error") {
                                console.log("重新尝试加载")
                                // 重新加载失败的URL
                                if (lastFailedUrl) {
                                    navigateToUrl(lastFailedUrl, false)
                                }
                            } else {
                                console.log("刷新欢迎页面")
                                showWelcomePage()
                            }
                        }
                    }
                }

                // 首页按钮
                Rectangle {
                    width: 40
                    height: 30
                    color: "#27ae60"
                    radius: 4

                    Text {
                        text: "🏠"
                        color: "white"
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("返回首页")
                            showWelcomePage()
                        }
                    }
                }
            }

            // 地址栏 - 默认为空
            Rectangle {
                id: addressBarContainer
                width: parent.width - 210  // 调整为更小，为右侧按钮腾出空间
                height: 30
                anchors.left: parent.left
                anchors.leftMargin: 150
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
                border.color: "#bdc3c7"
                border.width: 1
                radius: 4

                TextInput {
                    id: urlBar
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    clip: true
                    onAccepted: {
                        navigateToUrl(text.trim(), false)  // 默认不视为本地文件
                    }
                }

                // 自定义占位符文本
                Text {
                    text: "输入网址或搜索内容..."
                    color: "#95a5a6"
                    font.pixelSize: 14
                    anchors {
                        left: parent.left
                        leftMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                    visible: urlBar.text === ""
                }
            }

            // 右侧按钮区域
            Row {
                spacing: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                // // 下载按钮 - 恢复下载按钮
                // Rectangle {
                //     width: 40
                //     height: 30
                //     color: browserWindow.currentMode === "web" ? "#3498db" : "#bdc3c7"
                //     radius: 4

                //     // 简单判断是否是文件下载链接
                //     property bool isFileUrl: {
                //         if (browserWindow.currentMode !== "web") return false
                //         var currentUrl = webView.url.toString()
                //         if (!currentUrl) return false

                //         // 常见的文件扩展名
                //         var fileExtensions = [
                //             ".exe", ".msi", ".zip", ".rar", ".7z", ".tar", ".gz",
                //             ".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx",
                //             ".mp3", ".wav", ".flac", ".aac", ".m4a",
                //             ".mp4", ".avi", ".mkv", ".mov", ".wmv",
                //             ".jpg", ".jpeg", ".png", ".gif", ".bmp",
                //             ".iso", ".dmg", ".img"
                //         ]

                //         for (var i = 0; i < fileExtensions.length; i++) {
                //             if (currentUrl.toLowerCase().indexOf(fileExtensions[i]) !== -1) {
                //                 return true
                //             }
                //         }
                //         return false
                //     }

                //     Text {
                //         text: "↓️"
                //         color: "white"
                //         font.pixelSize: 16
                //         anchors.centerIn: parent
                //     }

                //     MouseArea {
                //         anchors.fill: parent
                //         enabled: browserWindow.currentMode === "web"
                //         onClicked: {
                //             console.log("下载当前页面")
                //             var currentUrl = webView.url.toString()
                //             if (currentUrl) {
                //                 // 调用桌面创建下载管理器
                //                 openDownloadManager(currentUrl)
                //             }
                //         }
                //     }
                // }

                // 新建窗口按钮
                Rectangle {
                    width: 40
                    height: 30
                    color: "#9b59b6"
                    radius: 4

                    Text {
                        text: "+"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("新建浏览器窗口")
                            createNewBrowserWindow("", false)
                        }
                    }
                }
            }
        }

        // WebEngineView - 显示网页
        WebEngineView {
            id: webView
            width: parent.width
            height: parent.height - toolbar.height
            anchors.top: toolbar.bottom
            visible: browserWindow.currentMode === "web"

            settings.javascriptEnabled: true
            settings.autoLoadImages: true
            settings.errorPageEnabled: true
            settings.pluginsEnabled: true
            settings.fullScreenSupportEnabled: true
            settings.webGLEnabled: true
            settings.autoLoadIconsForPage: true
            settings.touchIconsEnabled: true
            settings.focusOnNavigationEnabled: true
            settings.allowWindowActivationFromJavaScript: true
            settings.javascriptCanOpenWindows: true
            settings.javascriptCanAccessClipboard: true
            settings.localContentCanAccessRemoteUrls: true
            settings.localContentCanAccessFileUrls: true  // 允许访问本地文件
            settings.hyperlinkAuditingEnabled: true
            settings.scrollAnimatorEnabled: true

            // 处理新窗口请求
            onNewWindowRequested: function(request) {
                console.log("新窗口请求: " + request.requestedUrl)
                if (request.destination === WebEngineView.NewWindowInTab) {
                    // 标签页中打开，在当前窗口打开
                    request.openIn(webView)
                } else {
                    // 新窗口中打开，默认不视为本地文件
                    createNewBrowserWindow(request.requestedUrl, false)
                    request.accepted = true
                }
            }

            // 处理链接点击
            onLinkHovered: function(url) {
                console.log("链接悬停: " + url)
            }

            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebEngineView.LoadStartedStatus) {
                    console.log("开始加载: " + loadRequest.url)
                    browserWindow.windowTitle = "加载中..."
                    // 更新当前URL
                    currentUrl = loadRequest.url.toString()
                    browserWindow.currentMode = "web"
                } else if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    console.log("加载成功: " + loadRequest.url)
                    // 更新地址栏显示
                    urlBar.text = loadRequest.url.toString()
                    currentUrl = loadRequest.url.toString()
                    browserWindow.windowTitle = webView.title || "浏览器"
                } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                    console.log("加载失败: " + loadRequest.errorString)
                    browserWindow.lastError = loadRequest.errorString
                    browserWindow.lastFailedUrl = loadRequest.url.toString()

                    // 显示错误页面
                    showErrorPage(loadRequest.errorString, loadRequest.url.toString())
                }
            }

            onTitleChanged: {
                browserWindow.windowTitle = title || "浏览器"
            }

            // 修复：组件完成时使用统一的navigateToUrl函数处理initialUrl
            Component.onCompleted: {
                console.log("浏览器初始化，initialUrl:", initialUrl, "isLocalFile:", isLocalFile)
                if (initialUrl && initialUrl !== "") {
                    console.log("加载初始URL: " + initialUrl)
                    // 使用统一的navigateToUrl函数处理URL，使用传入的isLocalFile参数
                    navigateToUrl(initialUrl, isLocalFile)
                } else {
                    showWelcomePage()
                }
            }
        }

        // 欢迎页面
        WelcomePage {
            id: welcomePage
            anchors.fill: parent
            visible: browserWindow.currentMode === "welcome"

            onOpenUrl: function(url) {
                console.log("欢迎页面请求打开URL: " + url)
                navigateToUrl(url, false)
            }
        }

        // 错误页面
        ErrorPage {
            id: errorPage
            anchors.fill: parent
            visible: browserWindow.currentMode === "error"
            errorMessage: browserWindow.lastError
            failedUrl: browserWindow.lastFailedUrl

            onRefreshClicked: function() {
                console.log("错误页面请求刷新")
                if (browserWindow.lastFailedUrl) {
                    navigateToUrl(browserWindow.lastFailedUrl, false)
                }
            }

            onGoHomeClicked: function() {
                console.log("错误页面请求返回首页")
                showWelcomePage()
            }
        }
    }

    // 导航到URL - 根据传入的isLocalFile参数判断
    function navigateToUrl(input, isFile) {
        console.log("导航到URL:", input, "是否为文件:", isFile)

        if (input === "") {
            // 显示欢迎页面
            showWelcomePage()
            return
        }

        // 如果明确指定是文件，则按文件处理
        if (isFile) {
            console.log("按文件处理:", input)
            // 处理本地文件路径
            var fileUrl = input
            if (!fileUrl.startsWith("file://")) {
                // 将本地路径转换为 file:// URL
                fileUrl = "file:///" + fileUrl.replace(/\\/g, "/")
            }
            console.log("加载本地文件: " + fileUrl)
            webView.url = fileUrl
            urlBar.text = fileUrl
            currentUrl = fileUrl
            browserWindow.currentMode = "web"
            return
        }

        // 检查是否是file:// URL
        if (input.startsWith("file://")) {
            console.log("加载file:// URL: " + input)
            webView.url = input
            urlBar.text = input
            currentUrl = input
            browserWindow.currentMode = "web"
            return
        }

        // 检查是否已经是完整的URL（包含协议头）
        if (input.startsWith("http://") || input.startsWith("https://")) {
            console.log("导航到完整URL: " + input)
            webView.url = input
            urlBar.text = input
            currentUrl = input
            browserWindow.currentMode = "web"
            return
        }

        // 处理常见的域名格式（如 www.baidu.com）
        if (input.includes(".") && !input.includes(" ")) {
            // 如果包含点号但不包含空格，很可能是域名
            // 检查是否是常见的顶级域名
            var commonTLDs = [".com", ".org", ".net", ".edu", ".gov", ".cn", ".com.cn",
                             ".io", ".co", ".info", ".biz", ".me", ".tv", ".cc"]
            var isLikelyDomain = false

            for (var i = 0; i < commonTLDs.length; i++) {
                if (input.endsWith(commonTLDs[i]) ||
                    input.includes(commonTLDs[i] + "/") ||
                    input.includes(commonTLDs[i] + "?")) {
                    isLikelyDomain = true
                    break
                }
            }

            // 或者匹配常见的二级域名模式
            if (!isLikelyDomain) {
                var domainPattern = /^[a-zA-Z0-9-]+\.[a-zA-Z]{2,}$/
                if (domainPattern.test(input)) {
                    isLikelyDomain = true
                }
            }

            if (isLikelyDomain) {
                // 添加 https:// 前缀
                var url = "https://" + input
                console.log("导航到域名: " + url)
                webView.url = url
                urlBar.text = url
                currentUrl = url
                browserWindow.currentMode = "web"
            } else {
                // 否则视为搜索内容，使用百度搜索
                var searchUrl = "https://www.baidu.com/s?wd=" + encodeURIComponent(input)
                console.log("搜索内容: " + input + " -> " + searchUrl)
                webView.url = searchUrl
                urlBar.text = searchUrl
                currentUrl = searchUrl
                browserWindow.currentMode = "web"
            }
        } else {
            // 否则视为搜索内容，使用百度搜索
            var searchUrl = "https://www.baidu.com/s?wd=" + encodeURIComponent(input)
            console.log("搜索内容: " + input + " -> " + searchUrl)
            webView.url = searchUrl
            urlBar.text = searchUrl
            currentUrl = searchUrl
            browserWindow.currentMode = "web"
        }
    }

    // 显示欢迎页面
    function showWelcomePage() {
        console.log("显示欢迎页面")
        browserWindow.currentMode = "welcome"
        urlBar.text = ""
        currentUrl = ""
        browserWindow.windowTitle = "字研浏览器"
    }

    // 调用桌面创建下载管理器
    // function openDownloadManager(url) {
    //     // 获取桌面对象并调用其创建应用窗口的函数
    //     if (typeof desktop !== 'undefined' && desktop.createApplicationWindow) {
    //         desktop.createApplicationWindow("downloadmanager", url)
    //     } else {
    //         console.error("无法找到桌面对象或创建应用窗口的函数")
    //     }
    // }

    // 显示错误页面
    function showErrorPage(error, failedUrl) {
        console.log("显示错误页面，错误:", error, "URL:", failedUrl)
        browserWindow.currentMode = "error"
        browserWindow.lastError = error
        browserWindow.lastFailedUrl = failedUrl
        urlBar.text = failedUrl
        browserWindow.windowTitle = "加载失败"
    }

    // 创建新浏览器窗口 - 添加isLocalFile参数
    function createNewBrowserWindow(url, isFile) {
        console.log("创建新浏览器窗口，URL: " + url + ", 是否为文件: " + (isFile || false))
        var newBrowser = browserWindowComponent.createObject(desktop, {
            "initialUrl": url,
            "isLocalFile": isFile || false,
            "desktop": desktop,
            "settingsManager": settingsManager  // 新增：传递设置管理器
        })
        newBrowser.showWindow()
        desktop.openWindows.push({
            "window": newBrowser,
            "id": "browser_" + Date.now(),
            "type": "browser",
            "title": newBrowser.windowTitle
        })
        desktop.updateTaskbar()
    }
}
