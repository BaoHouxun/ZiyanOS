cmake_minimum_required(VERSION 3.16)
project(Launcher VERSION 1.0.0 LANGUAGES CXX)

# Windows平台特定的构建
if(WIN32)
    # 设置C++标准
    set(CMAKE_CXX_STANDARD 11)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)

    # 设置Windows应用程序（控制台程序，以便查看日志）
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /SUBSYSTEM:CONSOLE")

    # 添加可执行文件
    add_executable(Launcher
        src/main.cpp
    )

    # 设置目标属性
    set_target_properties(Launcher PROPERTIES
        WIN32_EXECUTABLE TRUE
        LINK_FLAGS "/ENTRY:mainCRTStartup"
    )

    # Windows链接库
    target_link_libraries(Launcher
        user32
        psapi
        shell32
    )

    # 设置输出目录 - 使用从主项目传递的目录
    if(LAUNCHER_OUTPUT_DIR)
        message(STATUS "设置启动器输出目录为: ${LAUNCHER_OUTPUT_DIR}")
        set_target_properties(Launcher PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${LAUNCHER_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${LAUNCHER_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${LAUNCHER_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${LAUNCHER_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${LAUNCHER_OUTPUT_DIR}"
        )
    else()
        # 如果未设置，输出到主项目构建目录
        get_filename_component(PARENT_BINARY_DIR ${CMAKE_BINARY_DIR} DIRECTORY)
        set(DEFAULT_OUTPUT_DIR "${PARENT_BINARY_DIR}")
        message(STATUS "使用默认输出目录: ${DEFAULT_OUTPUT_DIR}")
        set_target_properties(Launcher PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_DEBUG "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELEASE "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${DEFAULT_OUTPUT_DIR}"
            RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${DEFAULT_OUTPUT_DIR}"
        )
    endif()

    # 复制到输出目录的后处理命令
    add_custom_command(TARGET Launcher POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E echo "Launcher.exe 已构建到 $<TARGET_FILE_DIR:Launcher>"
    )

    message(STATUS "已配置启动器子项目")
else()
    message(STATUS "启动器仅支持Windows平台")
endif()