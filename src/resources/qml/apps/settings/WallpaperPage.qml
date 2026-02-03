// WallpaperPage.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ZiyanOS.FileSystem
import ZiyanOS.SettingsManager
import ZiyanOS.WallpaperManager

Item {
    id: wallpaperPage
    implicitHeight: wallpaperContent.height

    // 需要从父组件传入的属性
    property string currentBackground: "#1a1a1a"
    property string currentWallpaper: ""
    signal wallpaperChanged(string background, string wallpaperPath, string wallpaperName, string wallpaperDescription)

    // 文件选择器实例
    property var filePicker: null

    // 文件系统
    property var fileSystem: FileSystem {}

    // 设置管理器
    property var settingsManager: SettingsManager {}

    // 壁纸管理器
    property var wallpaperManager: WallpaperManager {
        id: wallpaperManager
        onWallpapersLoaded: {
            if (success) {
                // 更新系统壁纸列表
                systemWallpaperModel.clear()
                var wallpapers = wallpaperManager.wallpapers
                for (var i = 0; i < wallpapers.length; i++) {
                    var wp = wallpapers[i]
                    systemWallpaperModel.append({
                        id: wp.id,
                        name: wp.name,
                        description: wp.description,
                        imagePath: wp.imagePath
                    })
                }
            }
        }
    }

    // 当前选中的壁纸ID
    property string currentWallpaperId: ""
    property string currentWallpaperName: ""
    property string currentWallpaperDescription: ""

    // 系统壁纸数据模型
    ListModel {
        id: systemWallpaperModel
    }

    Column {
        id: wallpaperContent
        width: parent.width
        spacing: 20
        padding: 20

        // 当前壁纸预览
        Text {
            text: "当前壁纸预览"
            font.pixelSize: 18
            font.bold: true
            color: "#2c3e50"
        }

        // 预览区域
        Rectangle {
            id: wallpaperPreview
            width: Math.min(400, parent.width - 40)
            height: 250
            anchors.horizontalCenter: parent.horizontalCenter
            color: currentWallpaper === "" ? currentBackground : "transparent"
            border.color: "#bdc3c7"
            border.width: 2
            radius: 8

            // 如果设置了图片壁纸，显示图片
            Image {
                id: wallpaperImage
                anchors.fill: parent
                source: currentWallpaper
                fillMode: Image.PreserveAspectCrop
                visible: currentWallpaper !== ""
                asynchronous: true
            }

            // 纯色背景时的显示
            Rectangle {
                anchors.fill: parent
                color: currentBackground
                visible: currentWallpaper === ""
                radius: 8

                Text {
                    text: "纯色背景: " + currentBackground
                    color: "white"
                    font.pixelSize: 14
                    anchors.centerIn: parent
                }
            }

            // 加载指示器
            BusyIndicator {
                anchors.centerIn: parent
                running: wallpaperImage.status === Image.Loading
                visible: running
            }
        }

        // 壁纸信息
        Column {
            width: parent.width
            spacing: 8
            visible: currentWallpaper !== "" && currentWallpaperName !== ""

            Rectangle {
                width: parent.width
                height: 1
                color: "#e0e0e0"
            }

            // 壁纸名称
            Text {
                text: currentWallpaperName
                font.pixelSize: 16
                font.bold: true
                color: "#2c3e50"
                width: parent.width
                wrapMode: Text.Wrap
            }

            // 壁纸描述
            Text {
                text: currentWallpaperDescription
                font.pixelSize: 14
                color: "#7f8c8d"
                width: parent.width
                wrapMode: Text.Wrap
            }
        }

        // 系统壁纸
        Column {
            spacing: 15
            width: parent.width

            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: "系统壁纸"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#2c3e50"
                }

                // 刷新按钮
                Rectangle {
                    width: 80
                    height: 30
                    visible: false
                    color: "#3498db"
                    radius: 4

                    Row {
                        spacing: 5
                        anchors.centerIn: parent

                        Text {
                            text: "刷新"
                            color: "white"
                            font.pixelSize: 12
                        }

                        Text {
                            text: "🔄"
                            color: "white"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            loadSystemWallpapers()
                        }
                    }
                }
            }

            // 系统壁纸网格
            GridView {
                id: systemWallpaperGrid
                width: parent.width
                height: Math.ceil(systemWallpaperModel.count / 3) * 130
                cellWidth: parent.width / 3 - 20
                cellHeight: 100
                model: systemWallpaperModel
                clip: true
                visible: systemWallpaperModel.count > 0

                delegate: Rectangle {
                    width: systemWallpaperGrid.cellWidth - 10
                    height: systemWallpaperGrid.cellHeight - 10
                    color: "transparent"

                    // 壁纸缩略图容器
                    Rectangle {
                        width: parent.width - 20
                        height: 90
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#f5f5f5"
                        radius: 4
                        border.width: currentWallpaperId === model.id ? 2 : 0
                        border.color: "#3498db"

                        // 缩略图
                        Image {
                            anchors.fill: parent
                            source: model.imagePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        // 选中标记
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "#3498db"
                            visible: currentWallpaperId === model.id
                            anchors {
                                right: parent.right
                                top: parent.top
                                margins: 5
                            }

                            Text {
                                text: "✓"
                                color: "white"
                                font.pixelSize: 12
                                font.bold: true
                                anchors.centerIn: parent
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectSystemWallpaper(model.id, model.name, model.description, model.imagePath)
                            }
                        }
                    }

                    // 壁纸名称
                    Text {
                        text: model.name
                        color: "#2c3e50"
                        font.pixelSize: 12
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 2
                        elide: Text.ElideRight
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }

            // 没有系统壁纸的提示
            Rectangle {
                width: parent.width
                height: 80
                color: "#f8f9fa"
                radius: 6
                visible: systemWallpaperModel.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "暂无系统壁纸"
                        color: "#7f8c8d"
                        font.pixelSize: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "请在程序目录下的 wallpapers 文件夹中添加壁纸"
                        color: "#95a5a6"
                        font.pixelSize: 12
                        width: 300
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // 自定义壁纸
        Column {
            width: parent.width
            spacing: 10

            Text {
                text: "自定义壁纸"
                font.pixelSize: 14
                color: "#2c3e50"
            }

            Row {
                spacing: 10

                // 选择图片按钮
                Rectangle {
                    width: 120
                    height: 40
                    color: "#3498db"
                    radius: 5

                    Text {
                        text: "选择图片"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: showImagePicker()
                    }
                }

                // 纯色背景按钮
                Rectangle {
                    width: 120
                    height: 40
                    color: "#2ecc71"
                    radius: 5

                    Text {
                        text: "纯色背景"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: showColorPicker()
                    }
                }

                // 清除壁纸按钮
                Rectangle {
                    width: 120
                    height: 40
                    color: currentWallpaper !== "" ? "#e74c3c" : "#95a5a6"
                    radius: 5
                    enabled: currentWallpaper !== ""

                    Text {
                        text: "清除壁纸"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            clearWallpaper()
                        }
                    }
                }
            }
        }
    }

    // 加载系统壁纸
    function loadSystemWallpapers() {
        wallpaperManager.loadWallpapers()
    }

    // 选择系统壁纸
    function selectSystemWallpaper(id, name, description, imagePath) {
        currentWallpaperId = id
        currentWallpaperName = name
        currentWallpaperDescription = description
        currentWallpaper = imagePath

        // 发出信号通知壁纸改变
        wallpaperPage.wallpaperChanged("#1a1a1a", imagePath, name, description)
    }

    // 显示图片选择器
    function showImagePicker() {
        filePicker = filePickerComponent.createObject(wallpaperPage, {
            "selectFolder": false,
            "fileFilters": [".jpg", ".jpeg", ".png", ".bmp", ".gif"],
            "fileMode": "open"
        })

        filePicker.fileSelected.connect(function(path) {
            // 保存壁纸图片到本地（覆盖式）
            var savedWallpaperPath = settingsManager.saveWallpaperImage(path)

            if (savedWallpaperPath) {
                currentWallpaper = savedWallpaperPath
                currentWallpaperId = "custom"
                currentWallpaperName = "自定义壁纸"
                currentWallpaperDescription = "用户自定义壁纸"

                wallpaperPage.wallpaperChanged("#1a1a1a", savedWallpaperPath, "自定义壁纸", "用户自定义壁纸")
            }

            filePicker.destroy()
        })

        filePicker.canceled.connect(function() {
            filePicker.destroy()
        })

        filePicker.showWindow()
    }

    // 显示颜色选择器
    function showColorPicker() {
        colorPicker.open()
    }

    // 清除壁纸
    function clearWallpaper() {
        // 清除本地壁纸文件
        settingsManager.removeWallpaperFile()

        currentWallpaper = ""
        currentWallpaperId = ""
        currentWallpaperName = ""
        currentWallpaperDescription = ""

        wallpaperPage.wallpaperChanged(currentBackground, "", "", "")
    }

    // 颜色选择器对话框
    Dialog {
        id: colorPicker
        title: "选择背景颜色"
        modal: true
        width: 300
        height: 400
        anchors.centerIn: Overlay.overlay

        contentItem: Column {
            spacing: 10
            padding: 10

            Text {
                text: "预定义颜色"
                font.pixelSize: 14
                font.bold: true
                color: "#2c3e50"
            }

            Grid {
                columns: 4
                spacing: 5

                Repeater {
                    model: [
                        "#1a1a1a", "#2c3e50", "#34495e", "#16a085",
                        "#27ae60", "#2980b9", "#8e44ad", "#2c3e50",
                        "#c0392b", "#d35400", "#f39c12", "#7f8c8d"
                    ]

                    Rectangle {
                        width: 40
                        height: 40
                        color: modelData
                        radius: 5

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                currentBackground = modelData
                                currentWallpaper = ""
                                currentWallpaperId = ""
                                currentWallpaperName = ""
                                currentWallpaperDescription = ""

                                wallpaperPage.wallpaperChanged(modelData, "", "", "")
                                colorPicker.close()
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#e0e0e0"
            }

            Text {
                text: "自定义颜色"
                font.pixelSize: 14
                font.bold: true
                color: "#2c3e50"
            }

            Row {
                spacing: 10

                Rectangle {
                    width: 40
                    height: 40
                    color: currentBackground
                    border.color: "#bdc3c7"
                    border.width: 1
                }

                TextField {
                    id: colorInput
                    width: 120
                    placeholderText: "#000000"
                    text: currentBackground

                    onAccepted: {
                        if (text.startsWith("#") && text.length >= 4) {
                            currentBackground = text
                            currentWallpaper = ""
                            currentWallpaperId = ""
                            currentWallpaperName = ""
                            currentWallpaperDescription = ""

                            wallpaperPage.wallpaperChanged(text, "", "", "")
                            colorPicker.close()
                        }
                    }
                }
            }

            Button {
                text: "确定"
                onClicked: {
                    if (colorInput.text.startsWith("#") && colorInput.text.length >= 4) {
                        currentBackground = colorInput.text
                        currentWallpaper = ""
                        currentWallpaperId = ""
                        currentWallpaperName = ""
                        currentWallpaperDescription = ""

                        wallpaperPage.wallpaperChanged(colorInput.text, "", "", "")
                        colorPicker.close()
                    }
                }
            }
        }
    }

    // 文件选择器组件
    Component {
        id: filePickerComponent
        FilePicker {}
    }

    Component.onCompleted: {
        // 加载系统壁纸
        loadSystemWallpapers()

        // 初始化时检查是否有保存的壁纸文件
        var existingWallpaperPath = settingsManager.getWallpaperPath()
        if (existingWallpaperPath && currentWallpaper === "") {
            currentWallpaper = existingWallpaperPath
            currentWallpaperId = "custom"
            currentWallpaperName = "自定义壁纸"
            currentWallpaperDescription = "用户自定义壁纸"
        }
    }
}
