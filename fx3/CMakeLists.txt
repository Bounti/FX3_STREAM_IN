cmake_minimum_required(VERSION 3.8)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)
set(CMAKE_C_COMPILER_ID GNU)
set(CMAKE_CXX_COMPILER_ID GNU)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)

set(FX3_INSTALL_PATH "${CMAKE_BINARY_DIR}/cyfx3sdk/")
set(FX3_ELF2IMG_PATH "${CMAKE_BINARY_DIR}/cyfx3sdk/util/elf2img/")
set(FX3_DOWNLOAD_PATH "${CMAKE_BINARY_DIR}/cyusb_linux_1.0.5/")

function(download_file url filename hash_type hash)
if(NOT EXISTS ${filename})
  file(DOWNLOAD ${url} ${filename}
       TIMEOUT 60  # seconds
       EXPECTED_HASH ${hash_type}=${hash}
       TLS_VERIFY ON)
endif()
endfunction(download_file)

# project name
project(fx3_dmon.elf)

# download and install fx3 sdk
IF(NOT EXISTS ./fx3_sdk)
	#download_file(http://dlm.cypress.com.edgesuite.net/akdlm/downloadmanager/software/FX3_SDK_1.3.4_Linux.tar.gz ./fx3_sdk.tar.gz SHA1 662e95d1e4674108cbd16f6bef94be470f2d747f TIMEOUT 3600)
        file(DOWNLOAD http://dlm.cypress.com.edgesuite.net/akdlm/downloadmanager/software/FX3_SDK_1.3.4_Linux.tar.gz ./fx3_sdk.tar.gz SHOW_PROGRESS EXPECTED_HASH SHA1=662e95d1e4674108cbd16f6bef94be470f2d747f TIMEOUT 7200)
	file(ARCHIVE_EXTRACT INPUT ./fx3_sdk.tar.gz)
	file(ARCHIVE_EXTRACT INPUT ./ARM_GCC.tar.gz)
	file(ARCHIVE_EXTRACT INPUT ./cyusb_linux_1.0.5.tar.gz)
	file(ARCHIVE_EXTRACT INPUT ./fx3_firmware_linux.tar.gz)
endif()

# enable assembly support
enable_language(ASM)

set(CMAKE_SHARED_LIBRARY_LINK_C_FLAGS)

# select linker script
set(LINKER_SCRIPT "${FX3_INSTALL_PATH}/fw_build/fx3_fw/fx3.ld")

# define CPU OPTIONS
set(CPU_OPTIONS -mcpu=arm926ej-s -mthumb)

# optimizations (-O0 -O1 -O2 -O3 -Os -Ofast -Og -flto)
set(CMAKE_C_FLAGS_DEBUG "-O0 -g3 -DDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -g3")
set(CMAKE_C_FLAGS_RELEASE "-O0 -g3")
#"-Os -flto")
set(CMAKE_CXX_FLAGS_RELEASE "-O0 -g3")
#"-Os -flto")

add_definitions(
-D__CYU3P_TX__
)

add_compile_options(
  ${CPU_OPTIONS}
  -fmessage-length=0 
  -fsigned-char 
  -ffunction-sections 
  -fdata-sections 
  -Wall 
  -MMD -MP 
)

add_link_options(
  ${CPU_OPTIONS}
  -nostartfiles 
  -Xlinker --gc-sections 
  -Wl,-Map,${PROJECT_NAME}.map -Wl,-d -Wl,--no-wchar-size-warning -Wl,--entry,CyU3PFirmwareEntry
)

include_directories(
  ${CMAKE_SOURCE_DIR}
  "include" 
  "${FX3_INSTALL_PATH}/fw_lib/1_3_4/inc"
)

link_directories(
    ${CMAKE_SOURCE_DIR}
    "${FX3_INSTALL_PATH}/fw_lib/1_3_4/fx3_release"
)

add_subdirectory(src)

add_custom_target(load
  COMMAND echo "Generated and load FX3 image into the FX3 chip memory."
  COMMAND "${FX3_ELF2IMG_PATH}elf2img" -vectorload yes -i "./src/${PROJECT_NAME}" -o ${PROJECT_NAME}.img
  COMMAND export CYUSB_ROOT=$(pwd)/cyusb_linux_1.0.5
  COMMAND "${FX3_DOWNLOAD_PATH}src/download_fx3" -t I2C -i "./${PROJECT_NAME}.img"
  VERBATIM
)

add_custom_target(install_sdk
  COMMAND echo "Install the fx3 sdk"
  COMMAND bash ../install_sdk.sh
  VERBATIM
)

