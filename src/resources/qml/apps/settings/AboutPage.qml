import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Item {
    id: aboutPage
    implicitHeight: aboutContent.height

    // 信号：连续点击5次版本号时触发
    signal easterEggTriggered()

    Column {
        id: aboutContent
        width: parent.width
        spacing: 30
        padding: 40

        // Logo容器
        Item {
            id: logoContainer
            width: 280
            height: 120
            anchors.horizontalCenter: parent.horizontalCenter

            // 黑色圆角矩形背景 - 应该在底层
            Rectangle {
                id: logoBackground
                anchors.centerIn: parent
                width: 280
                height: 120
                radius: 15
                color: "#2c3e50"
                z: 0
            }

            // Logo图片
            Image {
                id: logoImage
                source: "qrc:/qt/qml/ZiyanOS/src/resources/assets/logo.png"
                width: 200
                height: 44
                anchors.centerIn: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                z: 1
            }

            // 阴影效果
            DropShadow {
                anchors.fill: logoBackground
                horizontalOffset: 2
                verticalOffset: 2
                radius: 8.0
                samples: 16
                color: "#80000000"
                source: logoBackground
                z: -1
            }
        }

        // 应用名称
        Text {
            text: "字研OS"
            color: "#2c3e50"
            font.pixelSize: 28
            font.bold: true
            font.family: "Microsoft YaHei"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 版本信息 - 可点击，用于触发彩蛋
        MouseArea {
            id: versionClickArea
            width: versionText.width
            height: versionText.height
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                versionClickCounter++
                console.log("版本号被点击，次数:", versionClickCounter)

                // 如果连续点击5次，触发彩蛋
                if (versionClickCounter >= 5) {
                    console.log("触发彩蛋！")
                    versionClickCounter = 0
                    easterEggTriggered()  // 触发信号
                } else {
                    // 如果不是5次，3秒后重置计数
                    resetTimer.restart()
                }
            }

            property int versionClickCounter: 0

            Timer {
                id: resetTimer
                interval: 3000
                onTriggered: {
                    versionClickArea.versionClickCounter = 0
                    console.log("点击计数已重置")
                }
            }

            Text {
                id: versionText
                text: "UI版本 1.1.0\n内核版本 11-251018"
                color: "#7f8c8d"
                font.pixelSize: 16
            }
        }

        // 分隔线
        Rectangle {
            width: 200
            height: 1
            color: "#dee2e6"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // 开发者信息
        Column {
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                text: "哔哩哔哩"
                color: "#2c3e50"
                font.pixelSize: 14
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "某哔用户"
                color: "#3498db"
                font.pixelSize: 16
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
