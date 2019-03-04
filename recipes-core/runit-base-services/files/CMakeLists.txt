CMAKE_MINIMUM_REQUIRED (VERSION 2.8.8)
project (runit-base-services C)

add_executable(pause pause.c)
add_executable(halt halt.c)

install(TARGETS
    halt
    pause 
    DESTINATION ${CMAKE_INSTALL_SBINDIR})
