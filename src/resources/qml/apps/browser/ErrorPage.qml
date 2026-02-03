import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: errorPage
    color: "#f5f7fa"
    anchors.fill: parent

    // 属性：错误信息和失败的URL
    property string errorMessage: "未知错误"
    property string failedUrl: ""

    // 信号：刷新页面和返回首页
    signal refreshClicked()
    signal goHomeClicked()

    Column {
        spacing: 20
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 500)

        // 错误图标
        Text {
            text: "⚠️"
            font.pixelSize: 50
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 错误标题
        Text {
            text: "页面加载失败"
            color: "#2c3e50"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 错误信息
        Text {
            text: errorPage.errorMessage
            color: "#7f8c8d"
            font.pixelSize: 14
            wrapMode: Text.Wrap
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        // 失败的URL（如果有）
        Text {
            visible: errorPage.failedUrl !== ""
            text: "网址: " + errorPage.failedUrl
            color: "#95a5a6"
            font.pixelSize: 12
            elide: Text.ElideMiddle
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }

        // 操作按钮
        Row {
            spacing: 15
            anchors.horizontalCenter: parent.horizontalCenter

            // 刷新按钮
            Rectangle {
                width: 100
                height: 40
                color: "#3498db"
                radius: 5

                Text {
                    text: "刷新页面"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        errorPage.refreshClicked()
                    }
                }
            }

            // 返回首页按钮
            Rectangle {
                width: 100
                height: 40
                color: "#27ae60"
                radius: 5

                Text {
                    text: "返回首页"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    anchors.centerIn: parent
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        errorPage.goHomeClicked()
                    }
                }
            }
        }

        // 建议说明
        Column {
            spacing: 8
            width: parent.width

            Text {
                text: "建议:"
                color: "#2c3e50"
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                text: "• 检查网络连接\n• 确认网址是否正确\n• 尝试刷新页面"
                color: "#7f8c8d"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                width: parent.width
            }
        }
    }
}
