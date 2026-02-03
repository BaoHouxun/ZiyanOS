import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ZiyanOS.SystemUtils 1.0

Item {
    id: resolutionPage
    implicitHeight: resolutionContent.height

    // 设置固定宽度并居中
    width: 400
    anchors.horizontalCenter: parent.horizontalCenter

    // 常用预设分辨率列表
    property var presetResolutions: [
        { width: 1920, height: 1080, name: "全高清 (1080p)" },
        { width: 2560, height: 1440, name: "2K (1440p)" },
        { width: 3840, height: 2160, name: "4K (2160p)" },
        { width: 1366, height: 768, name: "笔记本常见 (1366×768)" },
        { width: 1600, height: 900, name: "HD+ (1600×900)" },
        { width: 1280, height: 720, name: "高清 (720p)" },
        { width: 1024, height: 768, name: "XGA (1024×768)" },
        { width: 800, height: 600, name: "SVGA (800×600)" }
    ]

    // 当前分辨率信息
    property int currentScreenWidth: 0
    property int currentScreenHeight: 0
    property string currentResolution: ""

    // 计时器相关属性
    property int countdownSeconds: 15

    // 原始分辨率备份
    property int originalWidth: 0
    property int originalHeight: 0
    property bool hasOriginalBackup: false

    // SystemUtils实例 - 用于调用Windows API
    SystemUtils {
        id: systemUtils
    }

    Column {
        id: resolutionContent
        width: parent.width
        spacing: 10

        // 页面标题
        Text {
            text: "分辨率设置"
            font.pixelSize: 16
            font.bold: true
            color: "#2c3e50"
            anchors.horizontalCenter: parent.horizontalCenter
            padding: 8
        }

        // 当前分辨率显示
        Column {
            width: parent.width
            spacing: 8

            Text {
                text: "当前分辨率"
                font.pixelSize: 14
                color: "#2c3e50"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 当前分辨率信息卡片
            Rectangle {
                width: parent.width
                height: 60
                color: "#f8f9fa"
                radius: 4
                anchors.horizontalCenter: parent.horizontalCenter

                Row {
                    anchors.centerIn: parent
                    spacing: 40

                    Column {
                        spacing: 2
                        width: 120

                        Text {
                            text: "当前设置"
                            color: "#7f8c8d"
                            font.pixelSize: 11
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: currentScreenWidth + " × " + currentScreenHeight
                            color: "#2c3e50"
                            font.pixelSize: 16
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    Column {
                        spacing: 2
                        width: 80

                        Text {
                            text: "刷新率"
                            color: "#7f8c8d"
                            font.pixelSize: 11
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Text {
                            text: "60Hz"  // 这里可以扩展为从API获取实际刷新率
                            color: "#2c3e50"
                            font.pixelSize: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }

        // 预设分辨率选择
        Column {
            width: parent.width
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "预设分辨率"
                font.pixelSize: 14
                color: "#2c3e50"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 分辨率网格
            Grid {
                width: parent.width
                columns: 2
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    model: presetResolutions

                    Rectangle {
                        width: (parent.width - parent.spacing) / 2
                        height: 45
                        color: resolutionMouseArea.containsMouse ? "#e3f2fd" :
                               (currentScreenWidth === modelData.width && currentScreenHeight === modelData.height ? "#bbdefb" : "#f5f5f5")
                        radius: 4
                        border.color: currentScreenWidth === modelData.width && currentScreenHeight === modelData.height ? "#2196f3" : "transparent"
                        border.width: 2

                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            width: parent.width - 10

                            Text {
                                text: modelData.width + " × " + modelData.height
                                color: "#2c3e50"
                                font.pixelSize: 13
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.name
                                color: "#7f8c8d"
                                font.pixelSize: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: resolutionMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                console.log("选择分辨率:", modelData.width, "×", modelData.height)

                                // 检查是否与当前分辨率相同
                                if (currentScreenWidth === modelData.width && currentScreenHeight === modelData.height) {
                                    console.log("已选择当前分辨率，无需更改")
                                    return
                                }

                                // 保存原始分辨率（如果是第一次更改）
                                if (!hasOriginalBackup) {
                                    originalWidth = currentScreenWidth
                                    originalHeight = currentScreenHeight
                                    hasOriginalBackup = true
                                    console.log("备份原始分辨率:", originalWidth, "×", originalHeight)
                                }

                                // 显示确认对话框
                                confirmDialog.selectedWidth = modelData.width
                                confirmDialog.selectedHeight = modelData.height
                                confirmDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }

    // 确认对话框
    Dialog {
        id: confirmDialog
        modal: true
        title: "更改分辨率"
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: Overlay.overlay
        width: 400

        property int selectedWidth: 0
        property int selectedHeight: 0

        onAccepted: {
            console.log("应用新分辨率:", selectedWidth, "×", selectedHeight)
            applyResolution(selectedWidth, selectedHeight)
        }

        Column {
            spacing: 10
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "确定要将分辨率更改为 " + confirmDialog.selectedWidth + " × " + confirmDialog.selectedHeight + " 吗？"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
            }

            Text {
                text: "如果新分辨率不适合您的显示器，系统将在15秒后自动恢复。"
                font.pixelSize: 11
                color: "#f44336"
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 20
            }
        }
    }

    // 倒计时确认弹窗
    Dialog {
        id: countdownDialog
        modal: true
        title: "分辨率更改确认"
        anchors.centerIn: Overlay.overlay
        width: 400
        height: 200
        closePolicy: Popup.NoAutoClose  // 不允许用户关闭，必须选择

        property bool isActive: false

        onOpened: {
            isActive = true
            countdownSeconds = 15
            revertTimer.start()
        }

        onClosed: {
            isActive = false
            revertTimer.stop()
        }

        Column {
            anchors.centerIn: parent
            spacing: 15
            width: parent.width - 40

            // 倒计时文本
            Text {
                text: "将在 " + countdownSeconds + " 秒后恢复原始分辨率"
                color: "#5d4037"
                font.pixelSize: 14
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 进度条
            Rectangle {
                width: parent.width
                height: 6
                color: "#ffecb3"
                radius: 3
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: parent.width * (countdownSeconds / 15)
                    height: parent.height
                    color: "#ff9800"
                    radius: 3
                }
            }

            // 确认按钮
            Row {
                spacing: 20
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: 120
                    height: 36
                    color: "#4caf50"
                    radius: 6

                    Text {
                        text: "保持更改"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("用户确认保持分辨率更改")
                            // 停止计时器
                            revertTimer.stop()
                            countdownDialog.close()

                            // 确认保持更改后重置原始分辨率备份
                            hasOriginalBackup = false

                            // 更新当前分辨率显示已经在applyResolution中完成
                        }
                    }
                }

                Rectangle {
                    width: 120
                    height: 36
                    color: "#f44336"
                    radius: 6

                    Text {
                        text: "立即恢复"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            console.log("用户选择立即恢复原始分辨率")
                            // 停止计时器
                            revertTimer.stop()
                            countdownDialog.close()

                            // 立即恢复原始分辨率
                            restoreOriginalResolution()
                        }
                    }
                }
            }
        }
    }

    // 恢复倒计时计时器
    Timer {
        id: revertTimer
        interval: 1000
        repeat: true

        onTriggered: {
            countdownSeconds--

            if (countdownSeconds <= 0) {
                stop()
                console.log("倒计时结束，恢复原始分辨率")
                countdownDialog.close()
                restoreOriginalResolution()
            }
        }
    }

    // 应用新分辨率
    function applyResolution(width, height) {
        console.log("尝试设置分辨率:", width, "×", height)

        // 调用C++后端的Windows API
        var success = systemUtils.setResolution(width, height)

        if (success) {
            console.log("分辨率设置成功")

            // 更新当前分辨率显示
            currentScreenWidth = width
            currentScreenHeight = height
            currentResolution = currentScreenWidth + " × " + currentScreenHeight

            // 打开倒计时弹窗
            countdownSeconds = 15
            countdownDialog.open()
        } else {
            console.log("分辨率设置失败")
            // 显示错误消息
            errorDialog.open()
        }
    }

    // 恢复原始分辨率
    function restoreOriginalResolution() {
        console.log("恢复原始分辨率")

        // 调用C++后端恢复分辨率
        var success = systemUtils.restoreOriginalResolution()

        if (success) {
            console.log("原始分辨率恢复成功")

            // 如果备份了原始分辨率，则使用备份的值
            if (hasOriginalBackup) {
                console.log("使用备份的原始分辨率:", originalWidth, "×", originalHeight)
                currentScreenWidth = originalWidth
                currentScreenHeight = originalHeight
                currentResolution = currentScreenWidth + " × " + currentScreenHeight

                // 重置备份标志
                hasOriginalBackup = false
            } else {
                // 如果没有备份，则重新获取当前分辨率
                console.log("重新获取当前分辨率")
                updateCurrentResolution()
            }
        } else {
            console.log("恢复原始分辨率失败")
            // 即使API调用失败，也要尝试更新显示
            updateCurrentResolution()
            errorDialog.text = "恢复原始分辨率失败，已尝试重新获取当前分辨率。"
            errorDialog.open()
        }
    }

    // 错误对话框
    Dialog {
        id: errorDialog
        modal: true
        title: "错误"
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
        width: 350

        property string text: "无法设置分辨率，可能是不支持的分辨率或显示器不支持。"

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width - 20

            Text {
                text: errorDialog.text
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
            }
        }
    }

    // 初始化函数
    function initialize() {
        updateCurrentResolution()
    }

    // 更新当前分辨率信息
    function updateCurrentResolution() {
        // 获取主屏幕信息
        var primaryScreen = Qt.application.screens[0]
        if (primaryScreen) {
            currentScreenWidth = primaryScreen.width
            currentScreenHeight = primaryScreen.height
            currentResolution = currentScreenWidth + " × " + currentScreenHeight

            console.log("当前分辨率:", currentResolution)
        }
    }

    Component.onCompleted: {
        initialize()
    }
}
