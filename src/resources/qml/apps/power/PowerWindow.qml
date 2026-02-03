import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ZiyanOS.SystemUtils 1.0

ZiyanWindow {
    id: powerWindow
    width: 400
    height: 150  // 调整高度
    windowTitle: "电源选项"
    minimumWidth: 400
    minimumHeight: 220

    // SystemUtils实例
    SystemUtils {
        id: systemUtils
    }

    // 检测pecmd.ini的状态
    property bool hasPecmdIni: systemUtils.hasPecmdIni()

    // 添加信号：当需要关闭桌面时触发
    signal requestDesktopClose()

    contentItem: Item {
        anchors.fill: parent

        Column {
            spacing: 20
            anchors.centerIn: parent
            width: parent.width - 40

            // 环境状态提示 - 简单显示
            Text {
                text: hasPecmdIni ? "关机、重启将丢失未保存数据" : "非字研内核，关闭桌面"
                color: hasPecmdIni ? "black" : "#3498db"
                font.pixelSize: 14
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // 按钮区域 - 总是显示三个按钮
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter

                // 重启按钮
                Rectangle {
                    width: 100
                    height: 45
                    color: hasPecmdIni ? "#f39c12" : "#3498db"
                    radius: 8

                    Text {
                        text: "重启"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = hasPecmdIni ? "#d68910" : "#2980b9"
                        onExited: parent.color = hasPecmdIni ? "#f39c12" : "#3498db"
                        onClicked: {
                            console.log("用户点击重启按钮")
                            if (hasPecmdIni) {
                                // PE环境：执行重启命令
                                systemUtils.rebootWithCommand()
                            } else {
                                // 实体机环境：关闭桌面
                                console.log("实体机环境，发送关闭桌面请求信号")
                                powerWindow.requestDesktopClose()
                            }
                        }
                    }
                }

                // 关机按钮
                Rectangle {
                    width: 100
                    height: 45
                    color: hasPecmdIni ? "#e74c3c" : "#3498db"
                    radius: 8

                    Text {
                        text: "关机"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = hasPecmdIni ? "#c0392b" : "#2980b9"
                        onExited: parent.color = hasPecmdIni ? "#e74c3c" : "#3498db"
                        onClicked: {
                            console.log("用户点击关机按钮")
                            if (hasPecmdIni) {
                                // PE环境：执行关机命令
                                systemUtils.shutdownWithCommand()
                            } else {
                                // 实体机环境：关闭桌面
                                console.log("实体机环境，发送关闭桌面请求信号")
                                powerWindow.requestDesktopClose()
                            }
                        }
                    }
                }

                // 取消按钮
                Rectangle {
                    width: 100
                    height: 45
                    color: "#95a5a6"
                    radius: 8

                    Text {
                        text: "取消"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = "#7f8c8d"
                        onExited: parent.color = "#95a5a6"
                        onClicked: {
                            console.log("用户点击取消按钮，关闭电源窗口")
                            powerWindow.startCloseAnimation()
                        }
                    }
                }
            }
        }
    }

    // 窗口加载完成
    Component.onCompleted: {
        console.log("PowerWindow loaded, hasPecmdIni:", hasPecmdIni)
        console.log("当前环境:", hasPecmdIni ? "PE环境" : "实体机环境")
    }

    // 窗口关闭时的处理
    onWindowClosing: {
        console.log("电源窗口关闭")
    }
}
