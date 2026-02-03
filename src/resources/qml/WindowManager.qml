import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: windowManager
    width: 1
    height: 1
    visible: false
    title: "窗口管理器"

    // 属性：当前显示的窗口
    property var currentWindow: null

    // 窗口组件
    property Component lockScreenComponent: null
    property Component desktopComponent: null

    // 启动应用程序
    function launch() {
        console.log("启动应用程序，显示锁屏界面")

        // 创建锁屏窗口组件
        lockScreenComponent = Qt.createComponent("LockScreen.qml")
        if (lockScreenComponent.status === Component.Ready) {
            showLockScreen()
        } else {
            console.error("无法创建锁屏组件:", lockScreenComponent.errorString())
        }
    }

    // 显示锁屏窗口
    function showLockScreen() {
        console.log("显示锁屏窗口")

        // 如果已经有窗口，先关闭
        if (currentWindow) {
            currentWindow.close()
            currentWindow.destroy()
            currentWindow = null
        }

        // 创建新的锁屏窗口
        currentWindow = lockScreenComponent.createObject(null, {
            "visible": true
        })

        // 连接信号
        if (currentWindow) {
            currentWindow.loginSuccessful.connect(showDesktop)
            console.log("锁屏窗口创建成功")
        } else {
            console.error("无法创建锁屏窗口")
        }
    }

    // 显示桌面窗口
    function showDesktop() {
        console.log("显示桌面窗口")

        // 如果已经有窗口，先关闭
        if (currentWindow) {
            currentWindow.close()
            currentWindow.destroy()
            currentWindow = null
        }

        // 如果桌面组件还没有创建，先创建
        if (!desktopComponent) {
            desktopComponent = Qt.createComponent("Desktop.qml")
        }

        if (desktopComponent.status === Component.Ready) {
            // 创建新的桌面窗口
            currentWindow = desktopComponent.createObject(null, {
                "visible": true
            })

            // 为桌面窗口添加锁屏功能
            if (currentWindow) {
                // 确保桌面窗口有windowManager属性
                currentWindow.windowManager = windowManager

                console.log("桌面窗口创建成功")
            } else {
                console.error("无法创建桌面窗口")
            }
        } else {
            console.error("无法创建桌面组件:", desktopComponent.errorString())
        }
    }

    // 切换窗口
    function switchToDesktop() {
        showDesktop()
    }

    function switchToLockScreen() {
        showLockScreen()
    }

    Component.onCompleted: {
        console.log("窗口管理器初始化完成")
        // 启动应用程序
        Qt.callLater(launch)
    }

    // 当最后一个窗口关闭时退出应用
    onClosing: {
        console.log("窗口管理器关闭，退出应用程序")
        Qt.quit()
    }
}
