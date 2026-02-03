import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: welcomePage
    color: "#f5f7fa"
    anchors.fill: parent

    // 信号：当点击链接或按钮时触发
    signal openUrl(string url)

    // 属性：可以自定义标题和副标题
    property string pageTitle: "欢迎使用字研浏览器"
    property string subtitle: "基于全新字研内核的现代化浏览器"
    property string version: "版本 1.0"

    Column {
        spacing: 20
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 600)

        // 标题
        Text {
            text: welcomePage.pageTitle
            color: "#27ae60"
            font.pixelSize: 28
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 副标题
        Text {
            text: welcomePage.subtitle
            color: "#7f8c8d"
            font.pixelSize: 16
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 功能特性
        Row {
            spacing: 15
            anchors.horizontalCenter: parent.horizontalCenter

            // 快速浏览
            Column {
                spacing: 8
                width: 120

                Text {
                    text: "🚀"
                    font.pixelSize: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "快速浏览"
                    color: "#2c3e50"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "极速加载页面"
                    color: "#7f8c8d"
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // 安全可靠
            Column {
                spacing: 8
                width: 120

                Text {
                    text: "🔒"
                    font.pixelSize: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "安全可靠"
                    color: "#2c3e50"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "保护隐私安全"
                    color: "#7f8c8d"
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            // 简洁易用
            Column {
                spacing: 8
                width: 120

                Text {
                    text: "🎯"
                    font.pixelSize: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "简洁易用"
                    color: "#2c3e50"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "直观界面设计"
                    color: "#7f8c8d"
                    font.pixelSize: 11
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        // 使用说明
        Text {
            text: "在地址栏输入网址开始浏览，或点击右上角的\"+\"按钮新建窗口"
            color: "#7f8c8d"
            font.pixelSize: 13
            wrapMode: Text.Wrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        // 版本信息
        Text {
            text: "字研浏览器 · " + welcomePage.version
            color: "#95a5a6"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
