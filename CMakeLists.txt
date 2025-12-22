cmake_minimum_required(VERSION 3.14)

project(account)
set(TARGET_LIB ${PROJECT_NAME})
set(BUILD_DIR temp)

if (EXISTS "${CMAKE_BINARY_DIR}/conanbuildinfo.cmake")
    include(${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    conan_basic_setup()
endif()

set(APP_INSTALL_DIR opt/bmc/apps/${PROJECT_NAME})
set(LUACLIB_INSTALL_DIR opt/bmc/apps/account/luaclib)
set(LUACLIB_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libiam/lualib-src)
set(CSR_INSTALL_DIR opt/bmc/csr)

find_package(libmc4lua REQUIRED)
find_package(openldap REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_search_module(GLIB REQUIRED glib-2.0)
pkg_search_module(GMODULE REQUIRED gmodule-2.0)
pkg_search_module(DBUS REQUIRED dbus-1)

if(BUILD_MANUFACTURE)
    add_definitions(-DG_BUILD_MANUFACTURE)
endif()

install(DIRECTORY src/lualib DESTINATION ${APP_INSTALL_DIR} OPTIONAL)
install(DIRECTORY include/ DESTINATION opt/bmc/lualib OPTIONAL)
install(DIRECTORY src/service DESTINATION ${APP_INSTALL_DIR} OPTIONAL)
install(DIRECTORY dist/user_conf/rootfs/ DESTINATION . USE_SOURCE_PERMISSIONS OPTIONAL)
install(FILES dist/config.cfg DESTINATION ${APP_INSTALL_DIR} OPTIONAL)
install(DIRECTORY gen/class DESTINATION ${APP_INSTALL_DIR} OPTIONAL)
install(DIRECTORY csr/ DESTINATION ${CSR_INSTALL_DIR} OPTIONAL)
install(FILES mds/schema.json DESTINATION ${APP_INSTALL_DIR}/mds OPTIONAL)
install(FILES mds/service.json DESTINATION ${APP_INSTALL_DIR}/mds OPTIONAL)

if(BUILD_MANUFACTURE OR ENABLE_TEST STREQUAL "ON")
    # 预置信息
    install(FILES manufacture/default_datas.lua RENAME datas.lua DESTINATION ${APP_INSTALL_DIR})
    install(FILES manufacture/default_password.lua DESTINATION ${APP_INSTALL_DIR})
    install(DIRECTORY gen/${PROJECT_NAME}/ DESTINATION ${APP_INSTALL_DIR} PATTERN datas.lua EXCLUDE)
else()
    install(DIRECTORY gen/${PROJECT_NAME}/ DESTINATION ${APP_INSTALL_DIR})
endif()

add_subdirectory("libiam/lualib-src")

if(ENABLE_TEST)
    install(DIRECTORY libiam/lualib/. DESTINATION opt/bmc/lualib/libiam)
else()
    install(DIRECTORY libiam/lualib/. DESTINATION opt/bmc/lualib/account)
endif()