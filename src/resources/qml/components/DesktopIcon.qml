import QtQuick
import QtQuick.Controls

Rectangle {
    id: desktopIcon
    width: 80
    height: 90
    color: "transparent"

    property string iconText: ""
    property string iconName: ""
    property string appId: ""  // 新增：应用ID
    property bool isSystemApp: false  // 新增：标记是否是系统应用
    signal clicked()
    signal rightClicked()  // 新增：右键点击信号

    Column {
        spacing: 8
        anchors.centerIn: parent

        Rectangle {
            width: 60
            height: 60
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                width: 50
                height: 50
                color: "#3498db"
                radius: 10
                anchors.centerIn: parent

                Text {
                    text: desktopIcon.iconText
                    color: "white"
                    font.pixelSize: 24
                    anchors.centerIn: parent
                }
            }
        }

        Text {
            text: desktopIcon.iconName
            color: "white"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
            wrapMode: Text.Wrap
            width: 70
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                // 右键点击，显示上下文菜单
                desktopIcon.rightClicked()
            } else {
                // 左键点击
                desktopIcon.clicked()
            }
        }
        onPressed: {
            if (pressedButtons & Qt.LeftButton) {
                parent.scale = 0.9
            }
        }
        onReleased: parent.scale = 1.0
    }
}
