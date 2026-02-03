import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import ZiyanOS.FileSystem

ZiyanWindow {
    id: videoPlayer
    width: 800
    height: 600
    windowTitle: "视频播放器"
    contentBackground: "#2c3e50"

    property string currentVideoPath: ""
    property var fileSystem: FileSystem {}
    
    property var filePicker: null

    // 标记是否正在关闭
    property bool isClosing: false
    // 标记是否全屏
    property bool isFullScreen: false

    // 视频播放器
    MediaPlayer {
        id: mediaPlayer
        audioOutput: AudioOutput {
            id: audioOutput
            volume: 0.5
        }
        videoOutput: videoOutput
        onPlaybackStateChanged: {
            if (!isClosing) {
                updatePlayButton()
                updatePositionInfo()
            }
        }
        onPositionChanged: {
            if (!isClosing) {
                updateProgress()
            }
        }
        onDurationChanged: {
            if (!isClosing) {
                updatePositionInfo()
                progressSlider.to = duration
            }
        }
    }

    // 窗口关闭时的处理
    onWindowClosing: {
        console.log("视频播放器窗口关闭，停止播放")
        isClosing = true
        stopVideo()
        mediaPlayer.source = ""
    }

    // 组件销毁时的清理
    Component.onDestruction: {
        console.log("视频播放器组件销毁，清理资源")
        if (mediaPlayer.playbackState !== MediaPlayer.StoppedState) {
            mediaPlayer.stop()
        }
        mediaPlayer.source = ""
    }

    contentItem: Item {
        anchors.fill: parent

        // 视频输出区域 - 居中显示
        Rectangle {
            id: videoContainer
            width: Math.min(parent.width, parent.height * 16/9)
            height: Math.min(parent.height - 120, parent.width * 9/16)
            anchors.centerIn: parent
            color: "#1a1a1a"

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                visible: currentVideoPath !== ""
            }

            // 当没有视频时显示的提示和打开按钮
            Column {
                spacing: 20
                anchors.centerIn: parent
                visible: currentVideoPath === ""

                Text {
                    text: "🎬"
                    font.pixelSize: 60
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "未打开视频"
                    font.pixelSize: 18
                    color: "white"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                // 打开文件按钮 - 在默认界面显示
                Rectangle {
                    width: 150
                    height: 40
                    color: "#3498db"
                    radius: 6
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        text: "打开视频文件"
                        color: "white"
                        font.pixelSize: 14
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (!isClosing) {
                                showVideoPicker()
                            }
                        }
                    }
                }
            }
        }

        // 顶部信息栏
        Rectangle {
            id: infoBar
            width: parent.width
            height: 40
            anchors.top: parent.top
            color: "#34495e"
            opacity: 0.8
            visible: currentVideoPath !== "" && !isClosing

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Text {
                    text: getFileName(currentVideoPath)
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: mediaPlayer.duration > 0 ?
                          formatTime(mediaPlayer.duration) + " • " +
                          (videoOutput.sourceRect.width ? Math.round(videoOutput.sourceRect.width) + "×" + Math.round(videoOutput.sourceRect.height) : "未知分辨率")
                          : "加载中..."
                    color: "#bdc3c7"
                    font.pixelSize: 12
                    Layout.preferredWidth: 180
                }
            }
        }

        // 底部控制栏
        Rectangle {
            id: controlBar
            width: parent.width
            height: 80
            anchors.bottom: parent.bottom
            color: "#34495e"
            opacity: 0.8
            visible: currentVideoPath !== "" && !isClosing

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10

                // 进度条
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        id: currentTimeText
                        text: formatTime(mediaPlayer.position)
                        color: "white"
                        font.pixelSize: 12
                        Layout.preferredWidth: 50
                    }

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: mediaPlayer.duration
                        value: mediaPlayer.position
                        enabled: mediaPlayer.playbackState !== MediaPlayer.StoppedState && !isClosing

                        background: Rectangle {
                            implicitWidth: 200
                            implicitHeight: 6
                            color: "#7f8c8d"
                            radius: 3
                        }

                        handle: Rectangle {
                            x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            implicitWidth: 16
                            implicitHeight: 16
                            radius: 8
                            color: progressSlider.pressed ? "#3498db" : "#ecf0f1"
                            border.color: "#3498db"
                        }

                        onMoved: {
                            if (!isClosing) {
                                mediaPlayer.position = value
                            }
                        }
                    }

                    Text {
                        id: totalTimeText
                        text: formatTime(mediaPlayer.duration)
                        color: "white"
                        font.pixelSize: 12
                        Layout.preferredWidth: 50
                    }
                }

                // 控制按钮区域
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 15

                    // 打开按钮
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#3498db"
                        radius: 20

                        Text {
                            text: "📁"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!isClosing) {
                                    showVideoPicker()
                                }
                            }
                        }
                    }

                    // 播放/暂停按钮
                    Rectangle {
                        id: playPauseButton
                        width: 50
                        height: 50
                        color: "#27ae60"
                        radius: 25

                        Text {
                            id: playPauseIcon
                            text: "▶"
                            color: "white"
                            font.pixelSize: 20
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!isClosing) {
                                    togglePlayPause()
                                }
                            }
                        }
                    }

                    // 停止按钮
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#e74c3c"
                        radius: 20

                        Text {
                            text: "⏹"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!isClosing) {
                                    stopVideo()
                                }
                            }
                        }
                    }

                    // 全屏按钮
                    Rectangle {
                        width: 40
                        height: 40
                        color: "#9b59b6"
                        radius: 20

                        Text {
                            text: isFullScreen ? "⛶" : "⛶"
                            font.pixelSize: 16
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!isClosing) {
                                    toggleFullScreen()
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // 音量控制
                    RowLayout {
                        spacing: 8

                        Text {
                            text: audioOutput.volume === 0 ? "🔇" : audioOutput.volume < 0.5 ? "🔈" : "🔊"
                            font.pixelSize: 16
                            color: "white"
                        }

                        Slider {
                            id: volumeSlider
                            width: 100
                            from: 0
                            to: 1
                            value: audioOutput.volume

                            background: Rectangle {
                                implicitWidth: 100
                                implicitHeight: 4
                                color: "#7f8c8d"
                                radius: 2
                            }

                            handle: Rectangle {
                                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                                implicitWidth: 12
                                implicitHeight: 12
                                radius: 6
                                color: volumeSlider.pressed ? "#3498db" : "#ecf0f1"
                                border.color: "#3498db"
                            }

                            onMoved: {
                                if (!isClosing) {
                                    audioOutput.volume = value
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 显示视频选择器
    function showVideoPicker() {
        if (isClosing) return

        filePicker = filePickerComponent.createObject(videoPlayer, {
            "selectFolder": false,
            "fileFilters": [".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v"],
            "fileMode": "open"
        })

        filePicker.fileSelected.connect(function(path) {
            if (!isClosing) {
                loadVideo(path)
            }
            filePicker.destroy()
        })

        filePicker.canceled.connect(function() {
            filePicker.destroy()
        })

        filePicker.showWindow()
    }

    // 加载视频
    function loadVideo(path) {
        if (isClosing) return

        console.log("加载视频: " + path)
        currentVideoPath = path
        videoPlayer.windowTitle = "视频播放器 - " + getFileName(path)
        mediaPlayer.source = "file:///" + path
        playVideo()
    }

    // 播放视频
    function playVideo() {
        if (currentVideoPath !== "" && !isClosing) {
            mediaPlayer.play()
        }
    }

    // 暂停/恢复视频
    function togglePlayPause() {
        if (currentVideoPath === "" || isClosing) return

        if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
            mediaPlayer.pause()
        } else {
            mediaPlayer.play()
        }
    }

    // 停止视频
    function stopVideo() {
        if (mediaPlayer.playbackState !== MediaPlayer.StoppedState) {
            mediaPlayer.stop()
        }
    }

    // 切换全屏
    function toggleFullScreen() {
        isFullScreen = !isFullScreen
        if (isFullScreen) {
            videoPlayer.showFullScreen()
        } else {
            videoPlayer.showNormal()
        }
    }

    // 更新播放按钮状态
    function updatePlayButton() {
        if (isClosing) return

        if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
            playPauseIcon.text = "⏸"
            playPauseButton.color = "#f39c12"
        } else {
            playPauseIcon.text = "▶"
            playPauseButton.color = "#27ae60"
        }
    }

    // 更新进度条
    function updateProgress() {
        if (!progressSlider.pressed && !isClosing) {
            progressSlider.value = mediaPlayer.position
        }
    }

    // 更新时间信息
    function updatePositionInfo() {
        if (!isClosing) {
            currentTimeText.text = formatTime(mediaPlayer.position)
            totalTimeText.text = formatTime(mediaPlayer.duration)
        }
    }

    // 格式化时间（毫秒转换为分:秒）
    function formatTime(milliseconds) {
        if (!milliseconds || isNaN(milliseconds)) return "00:00"

        var seconds = Math.floor(milliseconds / 1000)
        var minutes = Math.floor(seconds / 60)
        seconds = seconds % 60

        return minutes.toString().padStart(2, '0') + ":" + seconds.toString().padStart(2, '0')
    }

    // 获取文件名
    function getFileName(path) {
        if (!path) return ""
        var lastSlash = Math.max(path.lastIndexOf('\\'), path.lastIndexOf('/'))
        return path.substring(lastSlash + 1)
    }

    // 公共方法：打开视频文件
    function openVideo(path) {
        console.log("视频播放器 openVideo 被调用，路径:", path)
        if (path && typeof path === 'string') {
            Qt.callLater(function() {
                loadVideo(path)
            })
        } else {
            console.log("无效的文件路径参数")
        }
    }

    // 文件选择器组件
    Component {
        id: filePickerComponent
        FilePicker {}
    }

    // 键盘快捷键
    Keys.onPressed: (event) => {
        if (isClosing) return

        switch(event.key) {
            case Qt.Key_Space:
                togglePlayPause()
                event.accepted = true
                break
            case Qt.Key_O:
                if (event.modifiers & Qt.ControlModifier) {
                    showVideoPicker()
                    event.accepted = true
                }
                break
            case Qt.Key_S:
                stopVideo()
                event.accepted = true
                break
            case Qt.Key_F:
            case Qt.Key_F11:
                toggleFullScreen()
                event.accepted = true
                break
            case Qt.Key_Escape:
                if (isFullScreen) {
                    toggleFullScreen()
                    event.accepted = true
                }
                break
            case Qt.Key_Left:
                mediaPlayer.position = Math.max(0, mediaPlayer.position - 5000) // 后退5秒
                event.accepted = true
                break
            case Qt.Key_Right:
                mediaPlayer.position = Math.min(mediaPlayer.duration, mediaPlayer.position + 5000) // 前进5秒
                event.accepted = true
                break
        }
    }

    // 双击切换全屏 - 只在视频区域响应
    MouseArea {
        anchors.fill: videoContainer
        enabled: currentVideoPath !== "" && !isClosing
        onDoubleClicked: toggleFullScreen()

        // 添加单击播放/暂停功能
        onClicked: {
            if (!isClosing) {
                togglePlayPause()
            }
        }
    }

    Component.onCompleted: {
        forceActiveFocus()
    }
}
