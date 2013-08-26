# Check http://webdev.elementaryos.org/docs/developer-guide/cmake for documentation

cmake_minimum_required(VERSION 2.8)
cmake_policy(VERSION 2.6)

project(balistica C)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake )

#
# Base bits
#
set(VERSION "0.0.1+trunk")
set(VERSION_INFO "Release")

# Packaging filenamesnames.
set(ARCHIVE_BASE_NAME ${CMAKE_PROJECT_NAME}-${VERSION})
set(ARCHIVE_FULL_NAME ${ARCHIVE_BASE_NAME}.tar.xz)
set(ARCHIVE_DEBUILD_FULL_NAME ${CMAKE_PROJECT_NAME}_${VERSION}.orig.tar.xz)

#set(GLADE_FILES )

option(DEBUG "Build for debugging." OFF)

if (DEBUG)
    message(STATUS "Debug build")
endif ()

find_package(PkgConfig)

#
# Uninstall target
#
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY
)

add_custom_target(
    uninstall-base
    COMMAND 
        ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake
    COMMAND 
        ${glib_schema_compiler} ${GSETTINGS_DIR}
)

add_custom_target(
    uninstall
)

# We add this dependency using add_dependencies (which makes it run first) rather than
# a depends clause in add_custom_target (which would make it run last).
add_dependencies(uninstall uninstall-base)

# This gets fired in the root-level Makefile to ensure an post-uninstall cleanup happens after
# everything has has been removed
add_custom_target(
    post-uninstall
)

# Dist
# This generates the dist tarballs
add_custom_target(
    dist
    COMMAND 
        git archive --prefix=${ARCHIVE_BASE_NAME}/ HEAD
        | xz -z > ${CMAKE_BINARY_DIR}/${ARCHIVE_FULL_NAME}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

add_subdirectory(help)
add_subdirectory(sql)
add_subdirectory(src)
