# Go cmake configuration
cmake_minimum_required(VERSION 3.16)
project(test_go)

set(TARGET shim_go)
set(GOPATH ${CMAKE_CURRENT_BINARY_DIR})

set(SRCS test.go)
set(LIB libgoshim.a)

add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${LIB}
  DEPENDS ${SRCS}
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  COMMAND go build -buildmode=c-archive
  -o "${CMAKE_CURRENT_BINARY_DIR}/${LIB}"
  ${CMAKE_GO_FLAGS} .
  COMMENT "Building Go library")

add_custom_target(${TARGET} DEPENDS ${LIB} ${HEADER})

add_library(goshim STATIC IMPORTED GLOBAL)
add_dependencies(goshim ${TARGET})
set_target_properties(goshim
  PROPERTIES
  IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/${LIB}
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_BINARY_DIR})
