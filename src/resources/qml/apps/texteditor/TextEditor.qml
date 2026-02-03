import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ZiyanOS.FileSystem

ZiyanWindow {
    id: textEditor
    width: 800
    height: 600
    windowTitle: "未命名 - 文本编辑器"

    property string currentFilePath: ""
    property bool isModified: false
    
    property var fileSystem: FileSystem {}

    // 文件选择器实例
    property var filePicker: null

    // 右键菜单
    property var contextMenu: null

    contentItem: Item {
        anchors.fill: parent

        // 工具栏
        Rectangle {
            id: toolbar
            width: parent.width
            height: 40
            color: "#ecf0f1"

            Row {
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10

                // 新建按钮
                Rectangle {
                    width: 70
                    height: 25
                    color: "#3498db"
                    radius: 3

                    Text {
                        text: "新建"
                        color: "white"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: newFile()
                    }
                }

                // 打开按钮
                Rectangle {
                    width: 70
                    height: 25
                    color: "#3498db"
                    radius: 3

                    Text {
                        text: "打开"
                        color: "white"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: showOpenFilePicker()
                    }
                }

                // 保存按钮
                Rectangle {
                    width: 70
                    height: 25
                    color: "#3498db"
                    radius: 3

                    Text {
                        text: "保存"
                        color: "white"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: saveFile(currentFilePath)
                    }
                }

                // 另存为按钮
                Rectangle {
                    width: 70
                    height: 25
                    color: "#3498db"
                    radius: 3

                    Text {
                        text: "另存为"
                        color: "white"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: showSaveFilePicker()
                    }
                }

                // 分隔线
                Rectangle {
                    width: 1
                    height: 20
                    color: "#bdc3c7"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 撤销按钮
                Rectangle {
                    width: 70
                    height: 25
                    color: textArea.canUndo ? "#3498db" : "#bdc3c7"
                    radius: 3

                    Text {
                        text: "撤销"
                        color: "white"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: textArea.canUndo
                        onClicked: textArea.undo()
                    }
                }

                // 重做按钮
                Rectangle {
                    width: 70
                    height: 25
                    color: textArea.canRedo ? "#3498db" : "#bdc3c7"
                    radius: 3

                    Text {
                        text: "重做"
                        color: "white"
                        font.pixelSize: 12
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: textArea.canRedo
                        onClicked: textArea.redo()
                    }
                }

                // 分隔线
                Rectangle {
                    width: 1
                    height: 20
                    color: "#bdc3c7"
                    anchors.verticalCenter: parent.verticalCenter
                }

                // 状态指示器
                Text {
                    text: isModified ? "已修改" : "已保存"
                    color: isModified ? "#e74c3c" : "#27ae60"
                    font.pixelSize: 12
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // 文本编辑区域
        ScrollView {
            width: parent.width
            height: parent.height - toolbar.height
            anchors.top: toolbar.bottom

            TextArea {
                id: textArea
                width: parent.width
                placeholderText: "在此输入文本..."
                wrapMode: TextArea.Wrap
                font.pixelSize: 14
                selectByMouse: true
                focus: true

                onTextChanged: {
                    if (!isModified) {
                        isModified = true
                        updateTitle()
                    }
                }

                // 右键菜单
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            showContextMenu(mouse.x, mouse.y)
                        }
                    }
                }

                // 快捷键处理
                Keys.onPressed: (event) => {
                    handleKeyEvent(event)
                }
            }
        }
    }

    // 右键菜单组件
    Component {
        id: contextMenuComponent

        Menu {
            id: contextMenu

            MenuItem {
                text: "撤销\tCtrl+Z"
                enabled: textArea.canUndo
                onTriggered: textArea.undo()
            }

            MenuItem {
                text: "重做\tCtrl+Y"
                enabled: textArea.canRedo
                onTriggered: textArea.redo()
            }

            MenuSeparator {}

            MenuItem {
                text: "剪切\tCtrl+X"
                enabled: textArea.selectedText !== ""
                onTriggered: textArea.cut()
            }

            MenuItem {
                text: "复制\tCtrl+C"
                enabled: textArea.selectedText !== ""
                onTriggered: textArea.copy()
            }

            MenuItem {
                text: "粘贴\tCtrl+V"
                onTriggered: textArea.paste()
            }

            MenuItem {
                text: "删除\tDel"
                enabled: textArea.selectedText !== ""
                onTriggered: {
                    textArea.remove(textArea.selectionStart, textArea.selectionEnd)
                }
            }

            MenuSeparator {}

            MenuItem {
                text: "全选\tCtrl+A"
                onTriggered: textArea.selectAll()
            }
        }
    }

    // 显示右键菜单
    function showContextMenu(x, y) {
        // 销毁现有的菜单
        if (contextMenu) {
            contextMenu.destroy()
            contextMenu = null
        }

        // 创建新的右键菜单
        contextMenu = contextMenuComponent.createObject(textEditor)
        contextMenu.popup(textArea, x, y)
    }

    // 处理快捷键
    function handleKeyEvent(event) {
        // Ctrl 组合键
        if (event.modifiers & Qt.ControlModifier) {
            switch (event.key) {
                case Qt.Key_N: // 新建
                    event.accepted = true
                    newFile()
                    break
                case Qt.Key_O: // 打开
                    event.accepted = true
                    showOpenFilePicker()
                    break
                case Qt.Key_S: // 保存
                    event.accepted = true
                    if (event.modifiers & Qt.ShiftModifier) {
                        // Ctrl+Shift+S 另存为
                        showSaveFilePicker()
                    } else {
                        // Ctrl+S 保存
                        saveFile(currentFilePath)
                    }
                    break
                case Qt.Key_Z: // 撤销
                    event.accepted = true
                    if (textArea.canUndo) {
                        textArea.undo()
                    }
                    break
                case Qt.Key_Y: // 重做
                    event.accepted = true
                    if (textArea.canRedo) {
                        textArea.redo()
                    }
                    break
                case Qt.Key_X: // 剪切
                    event.accepted = true
                    if (textArea.selectedText !== "") {
                        textArea.cut()
                    }
                    break
                case Qt.Key_C: // 复制
                    event.accepted = true
                    if (textArea.selectedText !== "") {
                        textArea.copy()
                    }
                    break
                case Qt.Key_V: // 粘贴
                    event.accepted = true
                    textArea.paste()
                    break
                case Qt.Key_A: // 全选
                    event.accepted = true
                    textArea.selectAll()
                    break
            }
        } else {
            // 其他快捷键
            switch (event.key) {
                case Qt.Key_F5: // 刷新/重新加载
                    event.accepted = true
                    if (currentFilePath) {
                        loadFile(currentFilePath)
                    }
                    break
                case Qt.Key_F12: // 开发者工具（调试用）
                    event.accepted = true
                    console.log("文本编辑器调试信息:")
                    console.log("文件路径:", currentFilePath)
                    console.log("文本长度:", textArea.length)
                    console.log("选中文本:", textArea.selectedText)
                    console.log("可撤销:", textArea.canUndo)
                    console.log("可重做:", textArea.canRedo)
                    break
            }
        }
    }

    // 显示打开文件选择器
    function showOpenFilePicker() {
        filePicker = filePickerComponent.createObject(textEditor, {
            "selectFolder": false,
            "fileFilters": [".txt", ".log", ".ini", ".conf", ".xml", ".json", ".js", ".css", ".html", ".htm"],
            "fileMode": "open" // 明确设置为打开模式
        })

        filePicker.fileSelected.connect(function(path) {
            loadFile(path)
            filePicker.destroy()
        })

        filePicker.canceled.connect(function() {
            filePicker.destroy()
        })

        filePicker.showWindow()
    }

    // 显示保存文件选择器
    function showSaveFilePicker() {
        filePicker = filePickerComponent.createObject(textEditor, {
            "selectFolder": false,
            "fileFilters": [".txt"],
            "defaultFileName": currentFilePath ? getFileName(currentFilePath) : "新文档.txt",
            "fileMode": "save" // 明确设置为保存模式
        })

        filePicker.fileSelected.connect(function(path) {
            saveFile(path)
            filePicker.destroy()
        })

        filePicker.canceled.connect(function() {
            filePicker.destroy()
        })

        filePicker.showWindow()
    }

    // 新建文件
    function newFile() {
        if (isModified) {
            // 简单提示，实际应用中可以实现保存对话框
            console.log("有未保存的更改，但继续新建文件")
        }
        textArea.text = ""
        currentFilePath = ""
        isModified = false
        updateTitle()
        textArea.forceActiveFocus()
    }

    // 加载文件 - 使用真实文件读取
    function loadFile(filePath) {
        if (!filePath || typeof filePath !== 'string') {
            console.log("无效的文件路径")
            return
        }

        console.log("加载文件: " + filePath)

        // 使用 FileSystem 读取文件
        var content = fileSystem.readFile(filePath)
        if (content !== "") {
            textArea.text = content
            currentFilePath = filePath
            isModified = false
            updateTitle()
            textArea.forceActiveFocus()
        }
        // 取消成功提示
    }

    // 保存文件 - 使用真实文件写入
    function saveFile(filePath) {
        if (!filePath) {
            showSaveFilePicker()
            return
        }

        // 确保文件扩展名
        if (filePath.indexOf('.') === -1) {
            filePath += ".txt"
        }

        console.log("保存文件到: " + filePath)

        // 使用 FileSystem 写入文件
        var success = fileSystem.writeFile(filePath, textArea.text)
        if (success) {
            currentFilePath = filePath
            isModified = false
            updateTitle()
            textArea.forceActiveFocus()
        }
        // 取消成功提示
    }

    // 显示消息
    function showMessage(message) {
        var messageBox = messageBoxComponent.createObject(textEditor, {
            "message": message
        })
        messageBox.showWindow()

        // 3秒后自动关闭
        messageTimer.start()
    }

    // 更新标题
    function updateTitle() {
        var title = currentFilePath ? getFileName(currentFilePath) : "未命名"
        if (isModified) {
            title += " *"
        }
        textEditor.windowTitle = title + " - 文本编辑器"
    }

    // 获取文件名
    function getFileName(path) {
        var lastSlash = Math.max(path.lastIndexOf('\\'), path.lastIndexOf('/'))
        return path.substring(lastSlash + 1)
    }

    // 公共方法：打开文件
    function openFile(path) {
        if (path && typeof path === 'string') {
            loadFile(path)
        } else {
            console.log("无效的文件路径参数")
        }
    }

    // 文件选择器组件
    Component {
        id: filePickerComponent
        FilePicker {}
    }

    // 消息框组件
    Component {
        id: messageBoxComponent
        ZiyanWindow {
            id: messageBox
            width: 300
            height: 150
            windowTitle: "消息"
            titleBarColor: "#27ae60"

            property string message: ""

            contentItem: Item {
                anchors.fill: parent

                Text {
                    text: messageBox.message
                    color: "#2c3e50"
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    anchors.centerIn: parent
                    anchors.margins: 20
                }
            }
        }
    }

    // 消息定时器
    Timer {
        id: messageTimer
        interval: 3000
        onTriggered: {
            // 安全地关闭所有消息窗口
            var children = textEditor.children
            if (children && children.length) {
                for (var i = 0; i < children.length; i++) {
                    var child = children[i]
                    if (child && child !== textEditor && child.windowTitle === "消息") {
                        child.close()
                    }
                }
            }
        }
    }

    // 连接文件系统的信号
    Connections {
        target: fileSystem
        function onFileOperationCompleted(message) {
            showMessage(message)
        }
        function onErrorOccurred(errorMessage) {
            showMessage(errorMessage)
        }
    }

    Component.onCompleted: {
        updateTitle()
        textArea.forceActiveFocus()
    }
}
