
set(PASSWOED_LIB iam_core)

string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UPPER)
add_definitions(-DBUILD_TYPE=BUILD_TYPE_${CMAKE_BUILD_TYPE_UPPER})

file(GLOB SOURCES "*.c" "../*.c")
add_library(${PASSWOED_LIB} SHARED ${SOURCES})
target_include_directories(${PASSWOED_LIB}
    PUBLIC ${LUACLIB_SRC_DIR}
    PUBLIC ${GLIB_INCLUDE_DIRS}
)
target_link_libraries(${PASSWOED_LIB}
    PUBLIC ${GLIB_LIBRARIES}
    PUBLIC libuip
    PUBLIC crypt
    PUBLIC vpp::vpp
    PUBLIC cyrus_sasl::cyrus_sasl
    PUBLIC openldap::openldap
    PUBLIC skynet::skynet
)

if(NOT (CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64"))
    message(STATUS "not dt mode, build pam_bmc_login")
    add_subdirectory("pam_bmc_login")
endif()

add_subdirectory("uip")

set_target_properties(${PASSWOED_LIB} PROPERTIES PREFIX "")
install(TARGETS ${PASSWOED_LIB} DESTINATION opt/bmc/luaclib/account PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
