set(UIP libuip)

file(GLOB SOURCES "*.c" "../common/*.c")
add_library(${UIP} SHARED ${SOURCES})

target_include_directories(${UIP}
    PUBLIC ${GLIB_INCLUDE_DIRS}
    PUBLIC ${DBUS_INCLUDE_DIRS}
)
target_link_libraries(${UIP}
    PUBLIC ${GLIB_LIBRARIES}
    PUBLIC ${DBUS_LIBRARIES}
    PUBLIC libmc4lua::libcutils
    PUBLIC liblogger::liblogger
    PUBLIC openldap::openldap
)

set_target_properties(${UIP} PROPERTIES PREFIX "")
if(ENABLE_TEST)
    install(TARGETS ${UIP} DESTINATION usr/lib64 PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
else()
    install(TARGETS ${UIP} DESTINATION opt/bmc/luaclib/account PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endif()