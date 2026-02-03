import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: calculatorButton
    height: 50
    radius: 5
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string text: ""
    property color color: "#34495e"

    signal clicked()

    Text {
        text: calculatorButton.text
        color: "black"
        font.pixelSize: 18
        font.bold: true
        anchors.centerIn: parent
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: calculatorButton.clicked()
        onPressed: calculatorButton.scale = 0.95
        onReleased: calculatorButton.scale = 1.0
        onEntered: calculatorButton.opacity = 0.8
        onExited: calculatorButton.opacity = 1.0
    }

    Component.onCompleted: {
        // 设置按钮颜色
        calculatorButton.color = calculatorButton.color
    }
}
