import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ZiyanOS.FileSystem
import ZiyanOS.SystemUtils

ZiyanWindow {
    id: fileBrowserWindow
    width: 800
    height: 600
    windowTitle: "文件浏览器"

    property string currentPath: ""
    property var fileSystem: FileSystem {}
    property var systemUtils: SystemUtils {}  // 新增：SystemUtils实例

    // 右键菜单相关属性
    property string selectedFilePath: ""
    property string selectedFileName: ""
    property int selectedFileIndex: -1

    // 对话框组件
    property var errorDialog: null
    property var confirmDeleteDialog: null
    property var renameDialog: null
    property var newFolderDialog: null  // 新增：新建文件夹对话框

    // 使用 contentItem 属性来设置窗口内容
    contentItem: Item {
        anchors.fill: parent

        // 地址栏和导航栏
        Rectangle {
            id: navigationBar
            width: parent.width
            height: 100  // 增加高度以容纳更多按钮
            color: "#f8f9fa"
            border.color: "#dee2e6"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 5

                // 第一行：导航按钮
                Row {
                    width: parent.width
                    height: 30
                    spacing: 10

                    // 返回计算机按钮 - 始终可用，除非已经在计算机界面
                    Rectangle {
                        width: 120
                        height: 30
                        color: currentPath === "" ? "#bdc3c7" : "#3498db"
                        radius: 4

                        Text {
                            text: "← 计算机"
                            color: "white"
                            font.pixelSize: 14
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: currentPath !== ""
                            onClicked: {
                                navigateTo("")
                            }
                        }
                    }

                    // 向上按钮 - 只有当有父目录时才可用
                    Rectangle {
                        width: 30
                        height: 30
                        color: parentDirectory !== "" ? "#3498db" : "#bdc3c7"
                        radius: 4

                        Text {
                            text: "↑"
                            color: "white"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parentDirectory !== ""
                            onClicked: {
                                if (parentDirectory !== "") {
                                    navigateTo(parentDirectory)
                                }
                            }
                        }
                    }
                    // 新增：刷新按钮 - 始终可用
                    Rectangle {
                        width: 30
                        height: 30
                        color: "#3498db"
                        radius: 4

                        Text {
                            text: "↻"
                            color: "white"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                refreshCurrentDirectory()
                            }
                        }
                    }
                    // 新增：新建文件夹按钮 - 只在非计算机界面时可用
                    Rectangle {
                        width: 120
                        height: 30
                        color: currentPath === "" ? "#bdc3c7" : "#27ae60"
                        radius: 4

                        Row {
                            spacing: 5
                            anchors.centerIn: parent

                            Text {
                                text: "新建文件夹"
                                color: "white"
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: currentPath !== ""
                            onClicked: {
                                showNewFolderDialog()
                            }
                        }
                    }
                }

                // 第二行：地址显示
                Row {
                    width: parent.width
                    height: 30

                    Text {
                        text: currentPath === "" ? "计算机" : currentPath
                        color: "#2c3e50"
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideLeft
                        width: parent.width - 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // 第三行：操作状态提示
                Text {
                    id: statusText
                    width: parent.width
                    height: 20
                    text: ""
                    color: "#7f8c8d"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }

        // 内容区域
        Rectangle {
            width: parent.width
            height: parent.height - navigationBar.height
            anchors.top: navigationBar.bottom
            color: "white"

            // 加载指示器
            Rectangle {
                id: loadingIndicator
                anchors.centerIn: parent
                width: 100
                height: 40
                color: "#3498db"
                radius: 5
                visible: false

                Text {
                    text: "加载中..."
                    color: "white"
                    font.pixelSize: 14
                    anchors.centerIn: parent
                }
            }

            // 文件列表
            ListView {
                id: fileList
                anchors.fill: parent
                anchors.margins: 10
                model: ListModel {}
                delegate: fileDelegate
                clip: true
                visible: !loadingIndicator.visible

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }

    // 文件项委托 - 计算机视图（显示驱动器）
    Component {
        id: computerDelegate

        Rectangle {
            width: fileList.width
            height: 60
            color: index % 2 === 0 ? "#f8f9fa" : "white"

            Row {
                spacing: 15
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10

                // 驱动器图标 - 统一使用相同的图标和颜色
                Rectangle {
                    width: 40
                    height: 40
                    color: model.type === "system" ? "#e74c3c" : "#3498db" // 系统盘红色，其他盘蓝色
                    radius: 8
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "💾" // 统一使用磁盘图标
                        font.pixelSize: 18
                        anchors.centerIn: parent
                    }
                }

                // 驱动器信息
                Column {
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: model.name
                        color: "#2c3e50"
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: model.type === "system" ? "系统分区 - " + model.size : "本地磁盘 - " + model.size
                        color: "#7f8c8d"
                        font.pixelSize: 12
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    navigateTo(model.path)
                }
            }
        }
    }

    // 文件项委托 - 文件浏览器视图（添加右键菜单）
    Component {
        id: fileDelegate

        Rectangle {
            id: fileItem
            width: fileList.width
            height: 50
            color: index % 2 === 0 ? "#f8f9fa" : "white"

            Row {
                spacing: 15
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10

                // 图标 - 根据文件类型显示不同图标
                Rectangle {
                    width: 30
                    height: 30
                    color: model.isDir ? "#3498db" : getFileColor(model.name)
                    radius: 5
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: model.isDir ? "📁" : getFileIcon(model.name)
                        font.pixelSize: 16
                        anchors.centerIn: parent
                    }
                }

                // 文件信息
                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: model.name
                        color: "#2c3e50"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        text: model.type + (model.size ? " · " + model.size : "") + " · " + (model.modified || "")
                        color: "#7f8c8d"
                        font.pixelSize: 12
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        // 右键点击，显示上下文菜单
                        selectedFilePath = model.path
                        selectedFileName = model.name
                        selectedFileIndex = index
                        contextMenu.popup()
                    } else {
                        // 左键点击
                        if (model.isDir) {
                            navigateTo(model.path)
                        }
                    }
                }
                onDoubleClicked: {
                    if (model.isDir) {
                        navigateTo(model.path)
                    } else {
                        // 根据文件类型处理
                        if (isTextFile(model.name)) {
                            openTextFile(model.path)
                        } else if (isWebFile(model.name)) {
                            openWebFile(model.path)
                        } else if (isImageFile(model.name)) {
                            openImageFile(model.path)
                        } else if (isMusicFile(model.name)) {
                            openMusicFile(model.path)
                        } else if (isVideoFile(model.name)) {
                            openVideoFile(model.path)
                        } else if (isExecutableFile(model.name)) {
                            openExecutableFile(model.path, model.name)
                        } else {
                            console.log("无法打开文件类型: " + model.name)
                            showErrorDialog("无法打开此文件类型: " + model.name)
                        }
                    }
                }
            }

            // 右键上下文菜单
            Menu {
                id: contextMenu

                MenuItem {
                    text: "打开"
                    onTriggered: {
                        if (fileList.model.get(selectedFileIndex).isDir) {
                            navigateTo(selectedFilePath)
                        } else {
                            openFileByType(selectedFilePath, selectedFileName)
                        }
                    }
                }

                MenuItem {
                    text: "重命名"
                    onTriggered: {
                        showRenameDialog(selectedFilePath, selectedFileName)
                    }
                }

                MenuItem {
                    text: "删除"
                    onTriggered: {
                        showConfirmDeleteDialog(selectedFilePath, selectedFileName)
                    }
                }

                // 新增：运行可执行文件的菜单项
                MenuItem {
                    text: "运行"
                    visible: isExecutableFile(selectedFileName)
                    onTriggered: {
                        openExecutableFile(selectedFilePath, selectedFileName)
                    }
                }
            }
        }
    }

    // 导航到指定路径
    function navigateTo(path) {
        loadingIndicator.visible = true
        statusText.text = "正在加载..."

        // 使用定时器模拟加载，避免UI阻塞
        timer.start()

        // 实际加载内容
        currentPath = path
        loadDirectoryContents(path)
    }

    // 加载目录内容
    function loadDirectoryContents(path) {
        fileList.model.clear()

        if (path === "") {
            // 显示驱动器列表 - 使用计算机视图委托
            fileList.delegate = computerDelegate
            var drives = fileSystem.getDrives()
            for (var i = 0; i < drives.length; i++) {
                fileList.model.append({
                    "name": drives[i].name,
                    "path": drives[i].path,
                    "isDir": true,
                    "type": drives[i].type === "system" ? "system" : "drive",
                    "size": drives[i].size,
                    "modified": "" // 确保包含 modified 属性
                })
            }
        } else {
            // 显示目录内容 - 使用文件浏览器视图委托
            fileList.delegate = fileDelegate
            var contents = fileSystem.getDirectoryContents(path)
            for (var j = 0; j < contents.length; j++) {
                // 确保每个项都有 modified 属性
                if (!contents[j].hasOwnProperty("modified")) {
                    contents[j].modified = ""
                }
                fileList.model.append(contents[j])
            }
        }

        loadingIndicator.visible = false
        statusText.text = contents ? `共 ${contents ? contents.length : drives.length} 个项目` : ""
    }

    // 新增：刷新当前目录
    function refreshCurrentDirectory() {
        if (currentPath === "") {
            statusText.text = "刷新驱动器列表..."
        } else {
            statusText.text = "刷新目录内容..."
        }

        loadingIndicator.visible = true

        // 使用定时器避免UI阻塞
        refreshTimer.start()
    }

    // 显示错误对话框
    function showErrorDialog(message) {
        // 如果已经有一个错误对话框，先关闭它
        if (errorDialog) {
            errorDialog.close()
        }

        errorDialog = errorDialogComponent.createObject(fileBrowserWindow, {
            "errorMessage": message
        })
        errorDialog.showWindow()
    }

    // 显示确认删除对话框
    function showConfirmDeleteDialog(filePath, fileName) {
        if (confirmDeleteDialog) {
            confirmDeleteDialog.close()
        }

        var isDirectory = fileSystem.isDir(filePath)
        var itemType = isDirectory ? "文件夹" : "文件"

        confirmDeleteDialog = confirmDeleteDialogComponent.createObject(fileBrowserWindow, {
            "filePath": filePath,
            "fileName": fileName,
            "itemType": itemType
        })
        confirmDeleteDialog.showWindow()
    }

    // 显示重命名对话框
    function showRenameDialog(filePath, fileName) {
        if (renameDialog) {
            renameDialog.close()
        }

        renameDialog = renameDialogComponent.createObject(fileBrowserWindow, {
            "filePath": filePath,
            "fileName": fileName
        })
        renameDialog.showWindow()
    }

    // 新增：显示新建文件夹对话框
    function showNewFolderDialog() {
        if (newFolderDialog) {
            newFolderDialog.close()
        }

        newFolderDialog = newFolderDialogComponent.createObject(fileBrowserWindow, {
            "parentPath": currentPath
        })
        newFolderDialog.showWindow()
    }

    // 执行删除操作
    function performDelete(filePath) {
        console.log("删除: " + filePath)
        var isDirectory = fileSystem.isDir(filePath)
        var success = false

        if (isDirectory) {
            success = fileSystem.deleteDirectory(filePath)
        } else {
            success = fileSystem.deleteFile(filePath)
        }

        if (success) {
            statusText.text = isDirectory ? "文件夹删除成功" : "文件删除成功"
            // 刷新当前目录
            navigateTo(currentPath)
        } else {
            statusText.text = "删除失败"
        }
    }

    // 执行重命名操作
    function performRename(oldPath, newName) {
        console.log("重命名: " + oldPath + " -> " + newName)

        // 构建新路径
        var parentDir = fileSystem.getParentDirectory(oldPath)
        var separator = Qt.platform.os === "windows" ? "\\" : "/"
        var newPath = parentDir + separator + newName

        var success = fileSystem.renameFile(oldPath, newPath)
        if (success) {
            statusText.text = "重命名成功"
            // 刷新当前目录
            navigateTo(currentPath)
        } else {
            statusText.text = "重命名失败"
        }
    }

    // 新增：执行新建文件夹操作
    function performNewFolder(parentPath, folderName) {
        console.log("新建文件夹: " + parentPath + " 名称: " + folderName)

        // 构建完整路径
        var separator = Qt.platform.os === "windows" ? "\\" : "/"
        var newFolderPath = parentPath + separator + folderName

        var success = fileSystem.createDirectory(newFolderPath)
        if (success) {
            statusText.text = "文件夹创建成功: " + folderName
            // 刷新当前目录
            navigateTo(currentPath)
        } else {
            statusText.text = "文件夹创建失败"
        }
    }

    // 根据文件类型打开文件
    function openFileByType(filePath, fileName) {
        if (isTextFile(fileName)) {
            openTextFile(filePath)
        } else if (isWebFile(fileName)) {
            openWebFile(filePath)
        } else if (isImageFile(fileName)) {
            openImageFile(filePath)
        } else if (isMusicFile(fileName)) {
            openMusicFile(filePath)
        } else if (isVideoFile(fileName)) {
            openVideoFile(filePath)
        } else if (isExecutableFile(fileName)) {
            openExecutableFile(filePath, fileName)
        } else {
            showErrorDialog("无法打开此文件类型: " + fileName)
        }
    }

    // 检查是否是文本文件
    function isTextFile(fileName) {
        var textExtensions = [".txt", ".log", ".ini", ".conf", ".xml", ".json", ".js", ".css"]
        var lowerName = fileName.toLowerCase()
        for (var i = 0; i < textExtensions.length; i++) {
            if (lowerName.endsWith(textExtensions[i])) {
                return true
            }
        }
        return false
    }

    // 检查是否是网页文件
    function isWebFile(fileName) {
        var webExtensions = [".html", ".htm", ".xhtml", ".php", ".asp", ".aspx", ".jsp"]
        var lowerName = fileName.toLowerCase()
        for (var i = 0; i < webExtensions.length; i++) {
            if (lowerName.endsWith(webExtensions[i])) {
                return true
            }
        }
        return false
    }

    function isImageFile(fileName) {
        var imageExtensions = [".jpg", ".jpeg", ".png", ".bmp", ".gif", ".svg", ".webp"]
        var lowerName = fileName.toLowerCase()
        for (var i = 0; i < imageExtensions.length; i++) {
            if (lowerName.endsWith(imageExtensions[i])) {
                return true
            }
        }
        return false
    }

    function isMusicFile(fileName) {
        var musicExtensions = [".mp3", ".wav", ".ogg", ".flac", ".aac", ".m4a", ".wma"]
        var lowerName = fileName.toLowerCase()
        for (var i = 0; i < musicExtensions.length; i++) {
            if (lowerName.endsWith(musicExtensions[i])) {
                return true
            }
        }
        return false
    }

    function isVideoFile(fileName) {
        var videoExtensions = [".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v"]
        var lowerName = fileName.toLowerCase()
        for (var i = 0; i < videoExtensions.length; i++) {
            if (lowerName.endsWith(videoExtensions[i])) {
                return true
            }
        }
        return false
    }

    // 新增：检查是否是可执行文件
    function isExecutableFile(fileName) {
        var execExtensions = [".exe", ".msi", ".bat", ".cmd", ".com", ".ps1", ".sh"]
        var lowerName = fileName.toLowerCase()
        for (var i = 0; i < execExtensions.length; i++) {
            if (lowerName.endsWith(execExtensions[i])) {
                return true
            }
        }
        return false
    }

    // 打开文本文件
    function openTextFile(filePath) {
        console.log("打开文本文件: " + filePath)
        createApplicationWindow("texteditor", filePath)
    }

    // 打开图片文件
    function openImageFile(filePath) {
        console.log("打开图片文件: " + filePath)
        createApplicationWindow("imageviewer", filePath)
    }

    // 打开网页文件
    function openWebFile(filePath) {
        console.log("打开网页文件: " + filePath)
        // 传递一个对象，包含文件路径和是否为本地文件的标志
        createApplicationWindow("browser", {
            url: filePath,
            isLocalFile: true
        })
    }

    // 打开音乐文件
    function openMusicFile(filePath) {
        console.log("打开音乐文件: " + filePath)
        createApplicationWindow("musicplayer", filePath)
    }

    // 打开视频文件
    function openVideoFile(filePath) {
        console.log("打开视频文件: " + filePath)
        createApplicationWindow("videoplayer", filePath)
    }

    // 新增：打开可执行文件（直接调用C++后端）
    function openExecutableFile(filePath, fileName) {
        console.log("启动可执行文件: " + filePath)

        // 更新状态文本
        statusText.text = "正在启动: " + fileName + "..."

        // 直接调用C++后端启动应用
        var success = systemUtils.startApplication(filePath)

        if (success) {
            statusText.text = "应用程序已启动: " + fileName
        } else {
            statusText.text = "启动失败: " + fileName
        }
    }

    // 获取文件图标
    function getFileIcon(fileName) {
        if (!fileName) return "📄"

        var ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        switch(ext) {
            case "txt": case "log": case "ini": case "conf": return "📄"
            case "pdf": return "📕"
            case "doc": case "docx": return "📝"
            case "xls": case "xlsx": return "📊"
            case "ppt": case "pptx": return "📑"
            case "jpg": case "jpeg": case "png": case "gif": case "bmp": case "svg": return "🖼️"
            case "mp3": case "wav": case "flac": case "aac": return "🎵"
            case "mp4": case "avi": case "mkv": case "mov": case "wmv": return "🎬"
            case "zip": case "rar": case "7z": case "tar": case "gz": return "📦"
            case "exe": case "com": case "msi": case "bat": case "cmd": case "ps1": case "sh": return "⚙️" // 可执行文件图标
            case "html": case "htm": case "xhtml": case "php": case "asp": case "aspx": case "jsp": return "🌐" // 网页文件图标
            case "css": return "🎨"
            case "js": return "📜"
            case "json": case "xml": return "🔣"
            case "py": return "🐍"
            case "java": return "☕"
            case "cpp": case "c": case "h": return "🔧"
            case "psd": case "ai": case "sketch": return "🎨"
            case "ttf": case "otf": case "woff": return "🔤"
            default: return "📄"
        }
    }

    // 获取文件图标背景颜色
    function getFileColor(fileName) {
        if (!fileName) return "#95a5a6"

        var ext = fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase()
        switch(ext) {
            case "txt": case "log": case "ini": case "conf": return "#3498db" // 蓝色 - 文本文件
            case "pdf": return "#e74c3c" // 红色 - PDF
            case "doc": case "docx": return "#2980b9" // 深蓝 - Word文档
            case "xls": case "xlsx": return "#27ae60" // 绿色 - Excel
            case "ppt": case "pptx": return "#e67e22" // 橙色 - PowerPoint
            case "jpg": case "jpeg": case "png": case "gif": case "bmp": case "svg": return "#9b59b6" // 紫色 - 图片
            case "mp3": case "wav": case "flac": case "aac": return "#f39c12" // 黄色 - 音频
            case "mp4": case "avi": case "mkv": case "mov": case "wmv": return "#d35400" // 深橙 - 视频
            case "zip": case "rar": case "7z": case "tar": case "gz": return "#16a085" // 青绿 - 压缩文件
            case "exe": case "com": case "msi": case "bat": case "cmd": case "ps1": case "sh": return "#2c3e50" // 深灰 - 可执行文件
            case "html": case "htm": case "xhtml": case "php": case "asp": case "aspx": case "jsp": return "#27ae60" // 绿色 - 网页文件
            case "css": return "#3498db" // 蓝色 - CSS
            case "js": return "#f39c12" // 黄色 - JavaScript
            case "json": case "xml": return "#7f8c8d" // 灰色 - 数据文件
            case "py": return "#3572A5" // Python蓝
            case "java": return "#ED8B00" // Java橙
            case "cpp": case "c": case "h": return "#00599C" // C++蓝
            case "psd": case "ai": case "sketch": return "#8E44AD" // 设计文件紫
            case "ttf": case "otf": case "woff": return "#E74C3C" // 字体红
            default: return "#95a5a6" // 默认灰色
        }
    }

    // 获取父目录 - 修复逻辑
    property string parentDirectory: {
        if (currentPath === "") {
            return ""  // 在计算机界面，没有父目录
        } else {
            var parent = fileSystem.getParentDirectory(currentPath)
            // 如果父目录是根目录（如C:\），则返回空字符串，表示应该回到计算机界面
            if (parent && (parent.endsWith(":\\") || parent === "/")) {
                return ""
            }
            return parent
        }
    }

    // 错误对话框组件
    Component {
        id: errorDialogComponent

        ZiyanWindow {
            id: errorDialog
            width: 400
            height: 200
            windowTitle: "错误"
            titleBarColor: "#e74c3c"

            property string errorMessage: ""

            contentItem: Item {
                anchors.fill: parent

                Column {
                    spacing: 20
                    anchors.centerIn: parent
                    width: parent.width - 40

                    Text {
                        text: "⚠️"
                        font.pixelSize: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: errorDialog.errorMessage
                        color: "#2c3e50"
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Rectangle {
                        width: 120
                        height: 35
                        color: "#3498db"
                        radius: 5
                        anchors.horizontalCenter: parent.horizontalCenter

                        Text {
                            text: "确定"
                            color: "white"
                            font.pixelSize: 14
                            font.bold: true
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                errorDialog.close()
                            }
                        }
                    }
                }
            }

            // 当窗口关闭时销毁自己
            onWindowClosing: {
                errorDialog.destroy()
            }
        }
    }

    // 确认删除对话框组件
    Component {
        id: confirmDeleteDialogComponent

        ZiyanWindow {
            id: confirmDeleteDialog
            width: 400
            height: 240
            windowTitle: "确认删除"
            titleBarColor: "#e74c3c"

            property string filePath: ""
            property string fileName: ""
            property string itemType: "文件"  // 区分文件和文件夹

            contentItem: Item {
                anchors.fill: parent

                Column {
                    spacing: 20
                    anchors.centerIn: parent
                    width: parent.width - 40

                    Text {
                        text: "⚠️"
                        font.pixelSize: 32
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "你确定要删除 " + confirmDeleteDialog.itemType + " \"" + confirmDeleteDialog.fileName + "\" 吗？"
                        color: "#2c3e50"
                        font.pixelSize: 16
                        font.bold: true
                        wrapMode: Text.Wrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        text: confirmDeleteDialog.itemType === "文件夹" ?
                              "此操作将删除文件夹及其所有内容，且无法撤销" :
                              "此操作无法撤销"
                        color: "#e74c3c"
                        font.pixelSize: 12
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Row {
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter

                        // 取消按钮
                        Rectangle {
                            width: 100
                            height: 35
                            color: "#95a5a6"
                            radius: 5

                            Text {
                                text: "取消"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    confirmDeleteDialog.close()
                                }
                            }
                        }

                        // 删除按钮
                        Rectangle {
                            width: 100
                            height: 35
                            color: "#e74c3c"
                            radius: 5

                            Text {
                                text: "删除"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    fileBrowserWindow.performDelete(confirmDeleteDialog.filePath)
                                    confirmDeleteDialog.close()
                                }
                            }
                        }
                    }
                }
            }

            // 当窗口关闭时销毁自己
            onWindowClosing: {
                confirmDeleteDialog.destroy()
            }
        }
    }

    // 重命名对话框组件
    Component {
        id: renameDialogComponent

        ZiyanWindow {
            id: renameDialog
            width: 400
            height: 220
            windowTitle: "重命名"
            titleBarColor: "#3498db"

            property string filePath: ""
            property string fileName: ""

            contentItem: Item {
                anchors.fill: parent

                Column {
                    spacing: 20
                    anchors.centerIn: parent
                    width: parent.width - 40

                    Text {
                        text: "重命名文件"
                        color: "#2c3e50"
                        font.pixelSize: 18
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // 文件名输入框
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "white"
                        border.color: "#bdc3c7"
                        border.width: 1
                        radius: 4

                        TextInput {
                            id: newNameInput
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            text: renameDialog.fileName
                            selectByMouse: true

                            onAccepted: {
                                performRenameAction()
                            }
                        }
                    }

                    Row {
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter

                        // 取消按钮
                        Rectangle {
                            width: 100
                            height: 35
                            color: "#95a5a6"
                            radius: 5

                            Text {
                                text: "取消"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    renameDialog.close()
                                }
                            }
                        }

                        // 确定按钮
                        Rectangle {
                            width: 100
                            height: 35
                            color: "#3498db"
                            radius: 5

                            Text {
                                text: "确定"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    performRenameAction()
                                }
                            }
                        }
                    }
                }
            }

            function performRenameAction() {
                if (newNameInput.text.trim() === "") {
                    fileBrowserWindow.showErrorDialog("文件名不能为空")
                    return
                }

                if (newNameInput.text === renameDialog.fileName) {
                    renameDialog.close()
                    return
                }

                fileBrowserWindow.performRename(renameDialog.filePath, newNameInput.text)
                renameDialog.close()
            }

            // 当窗口关闭时销毁自己
            onWindowClosing: {
                renameDialog.destroy()
            }
        }
    }

    // 新增：新建文件夹对话框组件
    Component {
        id: newFolderDialogComponent

        ZiyanWindow {
            id: newFolderDialog
            width: 400
            height: 220
            windowTitle: "新建文件夹"
            titleBarColor: "#27ae60"

            property string parentPath: ""

            contentItem: Item {
                anchors.fill: parent

                Column {
                    spacing: 20
                    anchors.centerIn: parent
                    width: parent.width - 40

                    Text {
                        text: "新建文件夹"
                        color: "#2c3e50"
                        font.pixelSize: 18
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "位置: " + (newFolderDialog.parentPath || "当前目录")
                        color: "#7f8c8d"
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // 文件夹名称输入框
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "white"
                        border.color: "#bdc3c7"
                        border.width: 1
                        radius: 4

                        TextInput {
                            id: folderNameInput
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                            text: "新建文件夹"
                            selectByMouse: true

                            onAccepted: {
                                performNewFolderAction()
                            }
                        }

                        // 占位符文本
                        Text {
                            text: "输入文件夹名称"
                            color: "#95a5a6"
                            font.pixelSize: 12
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            visible: folderNameInput.text === ""
                        }
                    }

                    Row {
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter

                        // 取消按钮
                        Rectangle {
                            width: 100
                            height: 35
                            color: "#95a5a6"
                            radius: 5

                            Text {
                                text: "取消"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    newFolderDialog.close()
                                }
                            }
                        }

                        // 创建按钮
                        Rectangle {
                            width: 100
                            height: 35
                            color: "#27ae60"
                            radius: 5

                            Text {
                                text: "创建"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    performNewFolderAction()
                                }
                            }
                        }
                    }
                }
            }

            function performNewFolderAction() {
                var folderName = folderNameInput.text.trim()
                if (folderName === "") {
                    fileBrowserWindow.showErrorDialog("文件夹名称不能为空")
                    return
                }

                // 检查文件夹名称是否包含非法字符
                var illegalChars = /[<>:"/\\|?*]/
                if (illegalChars.test(folderName)) {
                    fileBrowserWindow.showErrorDialog("文件夹名称不能包含以下字符: < > : \" / \\ | ? *")
                    return
                }

                fileBrowserWindow.performNewFolder(newFolderDialog.parentPath, folderName)
                newFolderDialog.close()
            }

            // 当窗口关闭时销毁自己
            onWindowClosing: {
                newFolderDialog.destroy()
            }
        }
    }

    // 加载定时器
    Timer {
        id: timer
        interval: 100
        onTriggered: {
            loadDirectoryContents(currentPath)
        }
    }

    // 新增：刷新定时器
    Timer {
        id: refreshTimer
        interval: 100
        onTriggered: {
            loadDirectoryContents(currentPath)
        }
    }

    // 连接文件系统的错误信号
    Connections {
        target: fileSystem
        function onErrorOccurred(errorMessage) {
            showErrorDialog(errorMessage)
        }
        function onFileOperationCompleted(message) {
            // 可以在这里显示成功消息
            console.log("文件操作完成: " + message)
        }
    }

    // 新增：连接SystemUtils的信号
    Connections {
        target: systemUtils
        function onApplicationStarted(appName, success) {
            if (success) {
                console.log("应用程序启动成功: " + appName)
            }
        }
        function onApplicationStartFailed(appName, error) {
            console.log("应用程序启动失败: " + appName + ", 错误: " + error)
            showErrorDialog("无法启动应用程序: " + appName + "\n错误: " + error)
        }
    }

    // 组件完成时显示驱动器列表
    Component.onCompleted: {
        navigateTo("")
    }
}
