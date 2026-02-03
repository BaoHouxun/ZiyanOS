import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ZiyanWindow {
    id: calculatorWindow
    width: 300
    height: 400
    windowTitle: "计算器"

    // 计算器状态
    property string displayText: "0"
    property string previousValue: ""
    property string currentOperation: ""
    property bool waitingForOperand: true
    

    // 使用 contentItem 属性来设置窗口内容
    contentItem: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // 显示屏
            Rectangle {
                id: display
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#2c3e50"
                radius: 5

                Text {
                    text: calculatorWindow.displayText
                    color: "white"
                    font.pixelSize: 24
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    anchors.fill: parent
                    anchors.margins: 10
                    elide: Text.ElideRight
                }
            }

            // 按钮网格
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                columnSpacing: 5
                rowSpacing: 5

                // 第一行: 清除按钮
                CalculatorButton {
                    text: "C"
                    color: "#e74c3c"
                    onClicked: clear()
                }

                CalculatorButton {
                    text: "±"
                    color: "#7f8c8d"
                    onClicked: toggleSign()
                }

                CalculatorButton {
                    text: "%"
                    color: "#7f8c8d"
                    onClicked: percentage()
                }

                CalculatorButton {
                    text: "÷"
                    color: "#f39c12"
                    onClicked: setOperation("÷")
                }

                // 第二行: 7 8 9 ×
                CalculatorButton {
                    text: "7"
                    onClicked: digitClicked("7")
                }

                CalculatorButton {
                    text: "8"
                    onClicked: digitClicked("8")
                }

                CalculatorButton {
                    text: "9"
                    onClicked: digitClicked("9")
                }

                CalculatorButton {
                    text: "×"
                    color: "#f39c12"
                    onClicked: setOperation("×")
                }

                // 第三行: 4 5 6 -
                CalculatorButton {
                    text: "4"
                    onClicked: digitClicked("4")
                }

                CalculatorButton {
                    text: "5"
                    onClicked: digitClicked("5")
                }

                CalculatorButton {
                    text: "6"
                    onClicked: digitClicked("6")
                }

                CalculatorButton {
                    text: "-"
                    color: "#f39c12"
                    onClicked: setOperation("-")
                }

                // 第四行: 1 2 3 +
                CalculatorButton {
                    text: "1"
                    onClicked: digitClicked("1")
                }

                CalculatorButton {
                    text: "2"
                    onClicked: digitClicked("2")
                }

                CalculatorButton {
                    text: "3"
                    onClicked: digitClicked("3")
                }

                CalculatorButton {
                    text: "+"
                    color: "#f39c12"
                    onClicked: setOperation("+")
                }

                // 第五行: 0 . =
                CalculatorButton {
                    text: "0"
                    Layout.columnSpan: 2
                    onClicked: digitClicked("0")
                }

                CalculatorButton {
                    text: "."
                    onClicked: decimalClicked()
                }

                CalculatorButton {
                    text: "="
                    color: "#f39c12"
                    onClicked: calculate()
                }
            }
        }
    }

    // 数字按钮点击
    function digitClicked(digit) {
        if (waitingForOperand) {
            displayText = digit
            waitingForOperand = false
        } else {
            if (displayText === "0" && digit === "0") {
                return
            }
            if (displayText === "0") {
                displayText = digit
            } else {
                displayText += digit
            }
        }
    }

    // 小数点点击
    function decimalClicked() {
        if (waitingForOperand) {
            displayText = "0."
            waitingForOperand = false
        } else if (displayText.indexOf(".") === -1) {
            displayText += "."
        }
    }

    // 设置运算操作
    function setOperation(op) {
        if (!waitingForOperand) {
            if (previousValue !== "" && currentOperation !== "") {
                calculate()
            } else {
                previousValue = displayText
            }
        }
        currentOperation = op
        waitingForOperand = true
    }

    // 计算
    function calculate() {
        if (previousValue === "" || currentOperation === "" || waitingForOperand) {
            return
        }

        var result = 0
        var prev = parseFloat(previousValue)
        var current = parseFloat(displayText)

        switch (currentOperation) {
            case "+":
                result = prev + current
                break
            case "-":
                result = prev - current
                break
            case "×":
                result = prev * current
                break
            case "÷":
                if (current === 0) {
                    displayText = "错误"
                    waitingForOperand = true
                    previousValue = ""
                    currentOperation = ""
                    return
                }
                result = prev / current
                break
        }

        // 处理浮点数精度
        if (result % 1 !== 0) {
            result = Math.round(result * 100000000) / 100000000
        }

        displayText = result.toString()
        previousValue = ""
        currentOperation = ""
        waitingForOperand = true
    }

    // 清除
    function clear() {
        displayText = "0"
        previousValue = ""
        currentOperation = ""
        waitingForOperand = true
    }

    // 切换正负号
    function toggleSign() {
        if (displayText !== "0") {
            if (displayText.charAt(0) === "-") {
                displayText = displayText.substring(1)
            } else {
                displayText = "-" + displayText
            }
        }
    }

    // 百分比
    function percentage() {
        var value = parseFloat(displayText)
        displayText = (value / 100).toString()
        waitingForOperand = true
    }
}
