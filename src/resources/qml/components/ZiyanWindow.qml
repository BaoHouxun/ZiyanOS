import QtQuick
import QtQuick.Controls
import QtQuick.Window

Window {
    id: ziyanWindow
    width: 400
    height: 300
    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false
    minimumWidth: 200
    minimumHeight: 150

    // 公共属性
    property string windowTitle: "窗口"
    property color titleBarColor: calculateTitleBarColor()  // 改为函数计算
    property alias contentItem: contentContainer.data
    property color contentBackground: "#ecf0f1"

    // 新增：计算标题栏文本颜色
    property color titleTextColor: calculateTextColor(titleBarColor)

    // 任务栏高度属性
    property int taskbarHeight: 50

    // 窗口调节相关属性
    property int borderWidth: 5
    property bool isResizing: false
    property point resizeStartPos: Qt.point(0, 0)
    property size resizeStartSize: Qt.size(0, 0)

    // 动画属性
    property real windowOpacityValue: 0.0
    property real windowScaleValue: 0.8
    property bool isClosing: false
    property bool isAnimating: false
    property bool isMinimized: false
    property point originalPosition: Qt.point(0, 0)
    property size originalSize: Qt.size(0, 0)
    property bool isMaximized: false

    // 新增：全局窗口设置属性（从设置管理器获取）
    property string globalWindowMode: "auto"
    property string globalWindowColor: "#3498db"

    // 新增：设置管理器引用（可选，用于获取最新设置）
    property var settingsManager: null

    // 信号
    signal windowClosing()
    signal windowActivated()
    signal windowMinimized()
    signal windowMaximized()
    signal windowRestored()

    // 主容器
    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: ziyanWindow.color
        radius: 8
        clip: true
        opacity: windowOpacityValue
        scale: windowScaleValue
        transformOrigin: Item.Center

        // 标题栏
        Rectangle {
            id: titleBar
            width: parent.width
            height: 35
            color: ziyanWindow.titleBarColor  // 使用计算后的颜色
            z: 1000
            topLeftRadius: 8
            topRightRadius: 8
            bottomLeftRadius: 0
            bottomRightRadius: 0

            // 标题文本 - 使用计算出的文本颜色
            Text {
                text: ziyanWindow.windowTitle
                color: titleTextColor
                font.pixelSize: 16
                font.bold: true
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            // 窗口控制按钮容器
            Row {
                id: windowControls
                spacing: 5
                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }
                z: 1001

                // 最小化按钮
                Rectangle {
                    id: minimizeBtn
                    width: 25
                    height: 25
                    color: "transparent"
                    radius: 4

                    Text {
                        text: "−"
                        color: titleTextColor
                        font.pixelSize: 16
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: minimizeBtn.color = (titleTextColor === "white" ? "#34495e" : "#95a5a6")
                        onExited: minimizeBtn.color = "transparent"
                        onClicked: {
                            minimizeWindow()
                        }
                    }
                }

                // 最大化/恢复按钮
                Rectangle {
                    id: maximizeBtn
                    width: 25
                    height: 25
                    color: "transparent"
                    radius: 4

                    Text {
                        text: isMaximized ? "⧉" : "⛶"
                        color: titleTextColor
                        font.pixelSize: 14
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: maximizeBtn.color = (titleTextColor === "white" ? "#34495e" : "#95a5a6")
                        onExited: maximizeBtn.color = "transparent"
                        onClicked: {
                            toggleMaximize()
                        }
                    }
                }

                // 关闭按钮
                Rectangle {
                    id: closeBtn
                    width: 25
                    height: 25
                    color: "transparent"
                    radius: 4

                    Text {
                        text: "×"
                        color: titleTextColor
                        font.pixelSize: 16
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: closeBtn.color = "#e74c3c"  // 保持红色背景
                        onExited: closeBtn.color = "transparent"
                        onClicked: {
                            startCloseAnimation()
                        }
                    }
                }
            }

            // 拖动区域
            MouseArea {
                anchors {
                    left: parent.left
                    right: windowControls.left
                    top: parent.top
                    bottom: parent.bottom
                }
                property point clickPos: "0,0"
                onPressed: (mouse) => {
                    clickPos = Qt.point(mouse.x, mouse.y)
                }
                onPositionChanged: (mouse) => {
                    if (!isMaximized) {
                        var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                        ziyanWindow.x += delta.x
                        ziyanWindow.y += delta.y
                    }
                }
                onDoubleClicked: {
                    toggleMaximize()
                }
            }
        }

        // 内容区域背景
        Rectangle {
            id: contentBackgroundRect
            width: parent.width
            height: parent.height - titleBar.height
            anchors.top: titleBar.bottom
            color: ziyanWindow.contentBackground
        }

        // 内容区域
        Item {
            id: contentContainer
            width: parent.width
            height: parent.height - titleBar.height
            anchors.top: titleBar.bottom
            clip: true
        }
    }

    // 右下角调节区域
    Rectangle {
        width: 20
        height: 20
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"
        z: 1001
        opacity: windowOpacityValue
        scale: windowScaleValue
        transformOrigin: Item.Center
        visible: !isAnimating && !isClosing && windowOpacityValue > 0.9 && !isMaximized

        // 调整大小图标指示
        Rectangle {
            width: 12
            height: 12
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: "transparent"

            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = "#95a5a6";
                    ctx.lineWidth = 1.5;
                    ctx.beginPath();
                    ctx.moveTo(width, height - 5);
                    ctx.lineTo(width - 5, height);
                    ctx.moveTo(width, height - 10);
                    ctx.lineTo(width - 10, height);
                    ctx.moveTo(width, height - 15);
                    ctx.lineTo(width - 15, height);
                    ctx.stroke();
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: {
                isResizing = true
                resizeStartPos = Qt.point(mouse.x, mouse.y)
                resizeStartSize = Qt.size(ziyanWindow.width, ziyanWindow.height)
            }
            onPositionChanged: {
                if (isResizing && pressed && !isMaximized) {
                    var deltaX = mouse.x - resizeStartPos.x
                    var deltaY = mouse.y - resizeStartPos.y

                    var newWidth = Math.max(ziyanWindow.minimumWidth, resizeStartSize.width + deltaX)
                    var newHeight = Math.max(ziyanWindow.minimumHeight, resizeStartSize.height + deltaY)

                    ziyanWindow.width = newWidth
                    ziyanWindow.height = newHeight
                }
            }
            onReleased: {
                isResizing = false
            }
        }
    }

    // 显示动画
    ParallelAnimation {
        id: showAnimation
        PropertyAnimation {
            target: ziyanWindow
            property: "windowOpacityValue"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "windowScaleValue"
            from: 0.8
            to: 1.0
            duration: 200
            easing.type: Easing.OutQuad
        }
        onStarted: {
            isAnimating = true
        }
        onFinished: {
            isAnimating = false
        }
    }

    // 关闭动画
    ParallelAnimation {
        id: closeAnimation
        PropertyAnimation {
            target: ziyanWindow
            property: "windowOpacityValue"
            from: 1.0
            to: 0.0
            duration: 150
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "windowScaleValue"
            from: 1.0
            to: 0.8
            duration: 150
            easing.type: Easing.InQuad
        }
        onStarted: {
            isAnimating = true
        }
        onFinished: {
            isAnimating = false
            if (isClosing) {
                ziyanWindow.windowClosing()
                ziyanWindow.close()
            }
        }
    }

    // 最小化动画 - 向下移动一小段距离并淡出（加快速度）
    ParallelAnimation {
        id: minimizeAnimation
        PropertyAnimation {
            target: ziyanWindow
            property: "y"
            to: ziyanWindow.y + 100  // 只下移100像素
            duration: 150  // 加快速度
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "windowOpacityValue"
            from: 1.0
            to: 0.0
            duration: 150  // 加快速度
            easing.type: Easing.InQuad
        }
        onStarted: {
            isAnimating = true
        }
        onFinished: {
            isAnimating = false
            ziyanWindow.visible = false
            isMinimized = true
            windowMinimized()
        }
    }

    // 恢复动画 - 向上移动一小段距离并淡入（加快速度）
    ParallelAnimation {
        id: restoreAnimation
        PropertyAnimation {
            target: ziyanWindow
            property: "y"
            from: ziyanWindow.y  // 从当前位置开始
            to: originalPosition.y
            duration: 150  // 加快速度
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "windowOpacityValue"
            from: 0.0
            to: 1.0
            duration: 150  // 加快速度
            easing.type: Easing.OutQuad
        }
        onStarted: {
            isAnimating = true
            ziyanWindow.visible = true
        }
        onFinished: {
            isAnimating = false
            isMinimized = false
            windowRestored()
        }
    }

    // 最大化动画 - 窗口从小连贯过渡到大
    ParallelAnimation {
        id: maximizeAnimation
        PropertyAnimation {
            target: ziyanWindow
            property: "x"
            to: 0
            duration: 250
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "y"
            to: 0
            duration: 250
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "width"
            to: Screen.width
            duration: 250
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "height"
            to: Screen.height - taskbarHeight
            duration: 250
            easing.type: Easing.OutQuad
        }
        onStarted: {
            isAnimating = true
        }
        onFinished: {
            isAnimating = false
            isMaximized = true
            windowMaximized()
        }
    }

    // 从最大化恢复动画 - 窗口从大连贯过渡到小
    ParallelAnimation {
        id: restoreFromMaximizeAnimation
        PropertyAnimation {
            target: ziyanWindow
            property: "x"
            to: originalPosition.x
            duration: 250
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "y"
            to: originalPosition.y
            duration: 250
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "width"
            to: originalSize.width
            duration: 250
            easing.type: Easing.OutQuad
        }
        PropertyAnimation {
            target: ziyanWindow
            property: "height"
            to: originalSize.height
            duration: 250
            easing.type: Easing.OutQuad
        }
        onStarted: {
            isAnimating = true
        }
        onFinished: {
            isAnimating = false
            isMaximized = false
            windowRestored()
        }
    }

    function calculateTitleBarColor() {
        // 优先使用传递的 settingsManager
        if (settingsManager) {
            globalWindowMode = settingsManager.windowTitleBarMode || "auto"
            globalWindowColor = settingsManager.windowTitleBarColor || "#3498db"
        } else if (typeof desktop !== 'undefined' && desktop.settingsManager) {
            // 如果未传递，尝试从桌面获取
            globalWindowMode = desktop.settingsManager.windowTitleBarMode || "auto"
            globalWindowColor = desktop.settingsManager.windowTitleBarColor || "#3498db"
        }

        // 根据模式返回颜色
        if (globalWindowMode === "custom") {
            return globalWindowColor
        } else {
            return contentBackground
        }
    }

    // 计算文本颜色函数：根据背景色返回黑色或白色
    function calculateTextColor(backgroundColor) {
       // 将颜色转换为 RGB 分量
       var r = backgroundColor.r * 255
       var g = backgroundColor.g * 255
       var b = backgroundColor.b * 255

       // 计算亮度 (W3C 公式)
       var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

       // 如果亮度 > 0.5，使用黑色文本；否则使用白色文本
       return luminance > 0.5 ? "black" : "white"
   }

    // 当相关属性改变时重新计算标题栏颜色
    onGlobalWindowModeChanged: {
        titleBarColor = calculateTitleBarColor()
        titleTextColor = calculateTextColor(titleBarColor)
    }

    onGlobalWindowColorChanged: {
        titleBarColor = calculateTitleBarColor()
        titleTextColor = calculateTextColor(titleBarColor)
    }

    onContentBackgroundChanged: {
        titleBarColor = calculateTitleBarColor()
        titleTextColor = calculateTextColor(titleBarColor)
    }

    // 当标题栏颜色改变时重新计算文本颜色
    onTitleBarColorChanged: {
        titleTextColor = calculateTextColor(titleBarColor)
    }

    onActiveChanged: {
        if (active) {
            windowActivated()
        }
    }

    // 公共方法
    function showWindow(x, y) {
        if (x !== undefined && y !== undefined) {
            ziyanWindow.x = x
            ziyanWindow.y = y
            originalPosition = Qt.point(x, y)
        } else {
            ziyanWindow.x = (Screen.width - ziyanWindow.width) / 2
            ziyanWindow.y = 50
            originalPosition = Qt.point(ziyanWindow.x, ziyanWindow.y)
        }

        originalSize = Qt.size(ziyanWindow.width, ziyanWindow.height)

        // 重置状态
        isClosing = false
        isAnimating = false
        isMinimized = false
        isMaximized = false
        windowOpacityValue = 0.0
        windowScaleValue = 0.8

        ziyanWindow.show()
        ziyanWindow.requestActivate()

        // 启动显示动画
        showAnimation.start()
    }

    // 启动关闭动画
    function startCloseAnimation() {
        if (!isClosing) {
            isClosing = true
            closeAnimation.start()
        }
    }

    // 最小化窗口
    function minimizeWindow() {
        if (!isMinimized && !isAnimating) {
            originalPosition = Qt.point(ziyanWindow.x, ziyanWindow.y)
            minimizeAnimation.start()
        }
    }

    // 恢复窗口
    function restoreWindow() {
        if (isMinimized && !isAnimating) {
            restoreAnimation.start()
        }
    }

    // 切换最大化状态 - 使用动画
    function toggleMaximize() {
        if (isAnimating) return;

        if (isMaximized) {
            // 从最大化恢复
            restoreFromMaximizeAnimation.start()
        } else {
            // 最大化窗口 - 保存当前位置和大小
            originalPosition = Qt.point(ziyanWindow.x, ziyanWindow.y)
            originalSize = Qt.size(ziyanWindow.width, ziyanWindow.height)
            maximizeAnimation.start()
        }
    }

    // 当窗口关闭时发出信号
    onClosing: {
        if (!isClosing) {
            close.accepted = false
            startCloseAnimation()
        } else {
            windowClosing()
        }
    }
}
