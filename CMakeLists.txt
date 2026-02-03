cmake_minimum_required(VERSION 3.16)

project(ZiyanOS VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找Qt6组件
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    Gui
    Multimedia
    WebEngineQuick
)

# 启用Qt的CMake集成
qt_standard_project_setup(REQUIRES 6.8)

# 检查CURL文件是否存在
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/include/curl/curl.h")
    message(WARNING "CURL头文件未找到在: ${CMAKE_CURRENT_SOURCE_DIR}/include/curl/curl.h")
else()
    message(STATUS "找到CURL头文件: ${CMAKE_CURRENT_SOURCE_DIR}/include/curl/curl.h")
endif()

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.lib")
    message(WARNING "libcurl.lib未找到在: ${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.lib")
else()
    message(STATUS "找到libcurl.lib: ${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.lib")
endif()

if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.dll")
    message(WARNING "libcurl.dll未找到在: ${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.dll")
else()
    message(STATUS "找到libcurl.dll: ${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.dll")
endif()

# 添加CURL为导入库（仅当文件存在时）
add_library(libcurl SHARED IMPORTED)

set_target_properties(libcurl PROPERTIES
    IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.lib"
    IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.dll"
)

# 收集所有C++源文件
set(CPP_SOURCES
    src/modules/filesystem/filesystem.cpp
    src/modules/settings/SettingsManager.cpp
    src/modules/system/SystemUtils.cpp
    src/modules/download/DownloadManager.cpp
    src/modules/mouseoverlay/MouseOverlayManager.cpp
    src/modules/logging/LogManager.cpp
    src/modules/wallpaper/WallpaperManager.cpp
    src/core/main.cpp
)

# 收集所有头文件
set(HEADER_FILES
    src/modules/filesystem/filesystem.h
    src/modules/settings/SettingsManager.h
    src/modules/system/SystemUtils.h
    src/modules/download/DownloadManager.h
    src/modules/mouseoverlay/MouseOverlayManager.h
    src/modules/logging/LogManager.h
    src/modules/wallpaper/WallpaperManager.h
)

# 添加可执行文件
add_executable(ZiyanOS
    ${CPP_SOURCES}
    ${HEADER_FILES}
)

# 配置QML模块
qt_add_qml_module(ZiyanOS
    URI ZiyanOS
    VERSION 1.0

    # 设置输出目录
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/ZiyanOS

    # QML文件 - 直接列出
    QML_FILES
        # 主桌面
        src/resources/qml/Desktop.qml

        # 新增：锁屏界面和主控制器
        src/resources/qml/LockScreen.qml
        src/resources/qml/WindowManager.qml

        # 通用组件
        src/resources/qml/components/DesktopIcon.qml
        src/resources/qml/components/ZiyanWindow.qml
        src/resources/qml/components/FilePicker.qml

        # 应用：计算器
        src/resources/qml/apps/calculator/CalculatorWindow.qml
        src/resources/qml/apps/calculator/CalculatorButton.qml

        # 应用：文本编辑器
        src/resources/qml/apps/texteditor/TextEditor.qml

        # 应用：图片查看器
        src/resources/qml/apps/imageviewer/ImageViewer.qml

        # 应用：音乐播放器
        src/resources/qml/apps/musicplayer/MusicPlayer.qml

        # 应用：视频播放器
        src/resources/qml/apps/videoplayer/VideoPlayer.qml

        # 应用：网页浏览器
        src/resources/qml/apps/browser/BrowserWindow.qml
        src/resources/qml/apps/browser/WelcomePage.qml
        src/resources/qml/apps/browser/ErrorPage.qml

        # 应用：文件浏览器
        src/resources/qml/apps/filebrowser/FileBrowserWindow.qml

        # 应用：电源菜单
        src/resources/qml/apps/power/PowerWindow.qml

        # 应用：设置
        src/resources/qml/apps/settings/SettingsWindow.qml
        src/resources/qml/apps/settings/AboutPage.qml
        src/resources/qml/apps/settings/WallpaperPage.qml
        src/resources/qml/apps/settings/WindowSettingsPage.qml
        src/resources/qml/apps/settings/ResolutionPage.qml

        # 应用：下载管理器
        src/resources/qml/apps/downloadmanager/DownloadManagerWindow.qml

        # 应用：彩蛋
        src/resources/qml/apps/easteregg/EasterEggWindow.qml

    RESOURCES
        # logo
        src/resources/assets/logo.png
        # 字体文件
        src/resources/fonts/NotoColorEmoji-Regular.ttf
        src/resources/fonts/SourceHanSansSC-Medium-2.otf
)

# 设置包含目录 - 关键修改！
# 添加${CMAKE_CURRENT_SOURCE_DIR}/include目录，这样#include <curl/curl.h>就能正确找到文件
target_include_directories(ZiyanOS PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/filesystem
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/settings
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/system
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/download
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/mouseoverlay
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/logging
    ${CMAKE_CURRENT_SOURCE_DIR}/src/modules/wallpaper
    ${CMAKE_CURRENT_SOURCE_DIR}/include  # 这一行是关键！添加项目根目录的include文件夹
)

# 链接Qt库和CURL库
target_link_libraries(ZiyanOS
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Gui
        Qt6::Multimedia
        Qt6::WebEngineQuick
        libcurl  # 添加CURL库
)

# Windows特定的链接库
if(WIN32)
    target_link_libraries(ZiyanOS PRIVATE
        ws2_32     # Winsock
        crypt32    # Crypto API
    )

    # 先获取主项目的输出目录
    get_target_property(MAIN_TARGET_OUTPUT_DIR ZiyanOS RUNTIME_OUTPUT_DIRECTORY)
    if(NOT MAIN_TARGET_OUTPUT_DIR)
        # 如果未设置，使用默认目录
        set(MAIN_TARGET_OUTPUT_DIR "${CMAKE_BINARY_DIR}")
    endif()

    message(STATUS "主程序输出目录: ${MAIN_TARGET_OUTPUT_DIR}")

    # 设置变量传递给子项目
    set(MOUSEOVERLAY_OUTPUT_DIR "${MAIN_TARGET_OUTPUT_DIR}" CACHE PATH "鼠标覆盖程序输出目录")

    # 添加鼠标覆盖子项目
    add_subdirectory(MouseOverlay)

    # 设置变量传递给 Launcher 子项目
    set(LAUNCHER_OUTPUT_DIR "${MAIN_TARGET_OUTPUT_DIR}" CACHE PATH "启动器输出目录")

    # 添加启动器子项目
    add_subdirectory(Launcher)

    # 设置Windows子系统
    set_target_properties(ZiyanOS PROPERTIES
        WIN32_EXECUTABLE TRUE
    )

    # 复制CURL dll到构建目录（后处理命令）
    add_custom_command(TARGET ZiyanOS POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/lib/libcurl.dll"
        $<TARGET_FILE_DIR:ZiyanOS>/
        COMMENT "Copying libcurl.dll to output directory"
    )
endif()

# 设置目标属性
set_target_properties(ZiyanOS PROPERTIES
    CXX_STANDARD 17
    CXX_STANDARD_REQUIRED ON
    CXX_EXTENSIONS OFF
)
