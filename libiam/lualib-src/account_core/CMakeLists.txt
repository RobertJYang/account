
set(ACCOUNT_LIB account_core)

string(TOUPPER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_UPPER)
add_definitions(-DBUILD_TYPE=BUILD_TYPE_${CMAKE_BUILD_TYPE_UPPER})

file(GLOB SOURCES "*.c" "../*.c")
add_library(${ACCOUNT_LIB} SHARED ${SOURCES})
target_include_directories(${ACCOUNT_LIB}
    PUBLIC ${GLIB_INCLUDE_DIRS}
)
target_link_libraries(${ACCOUNT_LIB}
    PUBLIC ${GLIB_LIBRARIES}
    PUBLIC liblogger::liblogger
    PUBLIC libmc4lua::libcutils
    PUBLIC skynet::skynet
    PUBLIC vpp::vpp
    PUBLIC crypt
)

set(ACCOUNT_C_LIB account_core_c)
file(GLOB PAM_SOURCES "../pam_tally_ext.c")
add_library(${ACCOUNT_C_LIB} SHARED ${PAM_SOURCES})
target_include_directories(${ACCOUNT_C_LIB}
    PUBLIC ${GLIB_INCLUDE_DIRS}
)
target_link_libraries(${ACCOUNT_C_LIB}
    PUBLIC ${GLIB_LIBRARIES}
    PUBLIC liblogger::liblogger
    PUBLIC libmc4lua::libcutils
    PUBLIC skynet::skynet
    PUBLIC vpp::vpp
    PUBLIC crypt
)

set_target_properties(${ACCOUNT_LIB} PROPERTIES PREFIX "")
install(TARGETS ${ACCOUNT_LIB} DESTINATION opt/bmc/luaclib PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
install(TARGETS ${ACCOUNT_C_LIB} DESTINATION usr/lib64 PERMISSIONS OWNER_READ OWNER_EXECUTE GROUP_READ GROUP_EXECUTE)
