set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.7 REQUIRED COMPONENTS Core Gui Widgets Qml Quick QuickControls2)

qt_standard_project_setup()

qt_add_executable(cavitation WIN32
    main.cpp
    core_bridge.cpp
    chat_list_model.cpp
    message_list_model.cpp
    text_links.cpp
    resources/cavitation.qrc
    resources/cavitation.rc)

target_include_directories(cavitation PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(cavitation PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    whatbubbles_cxx
    whatbubbles_core
    # Pulled in by the Rust staticlib rather than by anything here: rustpush
    # links Schannel, DPAPI and the CNG providers directly.
    ws2_32
    userenv
    bcrypt
    ncrypt
    secur32
    crypt32
    advapi32
    user32
    ntdll
    shell32
    # GetAdaptersAddresses, for ICE candidate gathering in the rtc crate that
    # came in with FaceTime support. Cargo does not propagate this one.
    iphlpapi)

set_target_properties(cavitation PROPERTIES
    OUTPUT_NAME "Cavitation"
    VS_DEBUGGER_WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}")

# Stages the Qt runtime beside the exe so the build directory is runnable
# without Qt on PATH.
if(WIN32)
    qt_generate_deploy_qml_app_script(
        TARGET cavitation
        OUTPUT_SCRIPT deploy_script
        NO_UNSUPPORTED_PLATFORM_ERROR)
    install(SCRIPT ${deploy_script})
endif()
