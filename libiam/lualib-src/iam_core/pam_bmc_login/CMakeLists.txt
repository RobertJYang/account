
set(PAM_BMC_LOGIN pam_bmc_login)

file(GLOB SOURCES "*.c" "../common/*.c")
add_library(${PAM_BMC_LOGIN} SHARED ${SOURCES})

target_include_directories(${PAM_BMC_LOGIN}
    PUBLIC ${GLIB_INCLUDE_DIRS}
)
target_link_libraries(${PAM_BMC_LOGIN}
    PUBLIC ${GLIB_LIBRARIES}
    PUBLIC libmc4lua::libcutils
    PUBLIC liblogger::liblogger
)

set_target_properties(${PAM_BMC_LOGIN} PROPERTIES PREFIX "")
install(TARGETS ${PAM_BMC_LOGIN} DESTINATION opt/bmc/luaclib/account PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)