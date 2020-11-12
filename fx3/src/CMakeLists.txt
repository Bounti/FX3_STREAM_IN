file(GLOB SOURCES
  ./cyfxtx.c
  ./dmon.c
  ./usbDescriptor.c
)

add_executable(${PROJECT_NAME} ${SOURCES} ${PROJECT_SOURCE_DIR}/src/cyfx_gcc_startup.S)
target_link_libraries(${PROJECT_NAME} cyu3lpp cyfxapi cyu3threadx c gcc)
SET_TARGET_PROPERTIES(${PROJECT_NAME} PROPERTIES LINKER_LANGUAGE C CXX ASM)
target_link_libraries(${PROJECT_NAME} ${LINK_OPTIONS} -T${LINKER_SCRIPT})
set_target_properties(${PROJECT_NAME} PROPERTIES LINK_DEPENDS ${LINKER_SCRIPT})

