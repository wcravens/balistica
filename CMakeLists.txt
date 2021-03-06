cmake_minimum_required(VERSION 3.0)
project(balistica C)
enable_testing(true)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# We use this so we can append the latest commit hash
# to the version string
include (GNUInstallDirs)
include(cmake/FindGit.cmake)
if(GIT_FOUND)
    GIT_WC_INFO(${PROJECT_SOURCE_DIR} Project)
endif()

#
# Version information
#
set(VERSION_MAJOR 2)
set(VERSION_MINOR 0)
set(VERSION_COMMIT ${Project_WC_REVISION_HASH})

# Anything other than "Release" will add the latest commit 
# hash when built to the version string
set(VERSION_DESC "Development")

if(NOT ${VERSION_DESC} MATCHES "Development")
	set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
else()
	set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}-${VERSION_COMMIT})
endif()

#
# Packaging filenamesnames
#
set(ARCHIVE_BASE_NAME ${CMAKE_PROJECT_NAME}-${VERSION})
set(ARCHIVE_FULL_NAME ${ARCHIVE_BASE_NAME}.tar.xz)

#
# Build options
#
option(DEBUG "Build for debugging." OFF)
option(ADD_COVERAGE "Add support for gcov code coverage tool." OFF)

if (DEBUG)
    message(STATUS "Compiling with DEBUG options")
endif ()

if(ADD_COVERAGE)
    message(STATUS "Adding GCOV support")
endif()

find_package(PkgConfig)

#
# Uninstall target
#
configure_file(
	"${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
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

# This gets fired in the root-level Makefile to ensure an post-uninstall cleanup
# happens after everything has has been removed.
add_custom_target(
	post-uninstall
)

#
# Dist - This generates the dist tarballs
#
add_custom_target(
	dist
	COMMAND git archive --prefix=${ARCHIVE_BASE_NAME}/ HEAD	| xz -z > ${CMAKE_BINARY_DIR}/${ARCHIVE_FULL_NAME}
		WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
	
        COMMAND md5sum ${CMAKE_BINARY_DIR}/${ARCHIVE_FULL_NAME} >> ${CMAKE_BINARY_DIR}/balistica-${VERSION}-checksum
	COMMAND	sha1sum ${CMAKE_BINARY_DIR}/${ARCHIVE_FULL_NAME} >> ${CMAKE_BINARY_DIR}/balistica-${VERSION}-checksum
	COMMAND	sha256sum ${CMAKE_BINARY_DIR}/${ARCHIVE_FULL_NAME} >> ${CMAKE_BINARY_DIR}/balistica-${VERSION}-checksum
)

add_subdirectory(data)
add_subdirectory(help)
add_subdirectory(sql)
add_subdirectory(src)
add_subdirectory(test)
