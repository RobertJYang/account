
set(IP_LOCK ip_lock)

file(GLOB SOURCES "*.c" "../common/*.c")
add_library(${IP_LOCK} SHARED ${SOURCES})

target_include_directories(${IP_LOCK}
    PUBLIC ${LUACLIB_SRC_DIR}
    PUBLIC ${GLIB_INCLUDE_DIRS}
    PUBLIC ${DBUS_INCLUDE_DIRS}
)
target_link_libraries(${IP_LOCK}
    PUBLIC ${GLIB_LIBRARIES}
    PUBLIC ${DBUS_LIBRARIES}
    PUBLIC libmc4lua::libcutils
    PUBLIC liblogger::liblogger
    PUBLIC skynet::skynet
)

set_target_properties(${IP_LOCK} PROPERTIES PREFIX "")
install(TARGETS ${IP_LOCK} DESTINATION usr/lib64 PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)