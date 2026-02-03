cmake_minimum_required(VERSION 3.16)
project(MouseOverlay VERSION 1.0.0 LANGUAGES CXX)

# Windows平台特定的构建
if(WIN32)
    # 设置C++标准
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)

    # 设置Windows应用程序（GUI程序）
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SUBSYSTEM:WINDOWS")

    # 添加可执行文件
    add_executable(MouseOverlay
        src/main.cpp
    )

    # 设置目标属性为Windows GUI程序
    set_target_properties(MouseOverlay PROPERTIES
        WIN32_EXECUTABLE TRUE
        LINK_FLAGS "/ENTRY:WinMain"
    )

    # Windows链接库
    target_link_libraries(MouseOverlay
        user32
        gdi32
    )

    # 设置输出目录 - 使用从主项目传递的目录
    if(MOUSEOVERLAY_OUTPUT_DIR)
        message(STATUS "设置鼠标覆盖程序输出目录为: ${MOUSEOVERLAY_OUTPUT_DIR}")
        set_target_properties(MouseOverlay PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${MOUSEOVERLAY_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${MOUSEOVERLAY_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${MOUSEOVERLAY_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${MOUSEOVERLAY_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${MOUSEOVERLAY_OUTPUT_DIR}"
        )
    else()
        # 如果未设置，输出到主项目构建目录
        get_filename_component(PARENT_BINARY_DIR ${CMAKE_BINARY_DIR} DIRECTORY)
        set(DEFAULT_OUTPUT_DIR "${PARENT_BINARY_DIR}")
        message(STATUS "使用默认输出目录: ${DEFAULT_OUTPUT_DIR}")
        set_target_properties(MouseOverlay PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${DEFAULT_OUTPUT_DIR}"
        )
    endif()

    # 复制到输出目录的后处理命令
    add_custom_command(TARGET MouseOverlay POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "MouseOverlay.exe 已构建到 $<TARGET_FILE_DIR:MouseOverlay>"
    )

    message(STATUS "已配置鼠标覆盖程序子项目")
else()
    message(STATUS "鼠标覆盖程序仅支持Windows平台")
endif()
