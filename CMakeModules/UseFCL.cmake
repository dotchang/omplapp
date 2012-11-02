include(FindPackageHandleStandardArgs)

# Check for FCL and CCD installation, otherwise download them.

### CCD LIBRARY ###
find_library (CCD_LIBRARY ccd DOC "Location of the CCD library (convex collision detection)")
find_path (CCD_INCLUDE_DIR ccd)
if (CCD_LIBRARY AND CCD_INCLUDE_DIR)
    find_package_handle_standard_args(ccd DEFAULT_MSG CCD_LIBRARY CCD_INCLUDE_DIR)
else (CCD_LIBRARY AND CCD_INCLUDE_DIR)

    message (STATUS "CCD library not found.  Will download and compile.")
    include(ExternalProject)
    # download ccd
    ExternalProject_Add (ccd
        DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/src/external"
        URL "http://libccd.danfis.cz/files/libccd-1.4.tar.gz"
        URL_MD5 "684a9f2f44567a12a30af383de992a89"
        CMAKE_ARGS
            "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/ccd-prefix"
            "-DCMAKE_BUILD_TYPE=Release" "-DCCD_DOUBLE=1" "-DCMAKE_C_FLAGS=-fPIC")

    # Set the CCD_LIBRARY Variable
    set(CCD_LIBRARY "${CMAKE_BINARY_DIR}/ccd-prefix/lib/${CMAKE_STATIC_LIBRARY_PREFIX}ccd${CMAKE_STATIC_LIBRARY_SUFFIX}")
    if(EXISTS "${CCD_LIBRARY}")
        set(CCD_LIBRARY "${CCD_LIBRARY}" CACHE FILEPATH "Location of convex collision detection library" FORCE)
    endif()

    # Set the CCD_INCLUDE_DIR Variable
    set(CCD_INCLUDE_DIR "${CMAKE_BINARY_DIR}/ccd-prefix/include")
    if(IS_DIRECTORY "${CCD_INCLUDE_DIR}")
        set(CCD_INCLUDE_DIR "${CCD_INCLUDE_DIR}" CACHE PATH "Location of convex collision detection header files" FORCE)
    endif()
endif (CCD_LIBRARY AND CCD_INCLUDE_DIR)

### FCL LIBRARY ###
find_package(PkgConfig)
if(PKG_CONFIG_FOUND)
    pkg_check_modules(FCL fcl QUIET)
    if(FCL_FOUND)
        set(FCL_LIBRARY "${FCL_LIBRARIES}")
        set(FCL_INCLUDE_DIR "${FCL_INCLUDE_DIRS}")
    endif()
else()
    find_library(FCL_LIBRARY fcl DOC "Location of FCL collision checking library")
    find_path(FCL_INCLUDE_DIR collision_object.h PATH_SUFFIXES "fcl" DOC "Location of FCL header files")
endif()

if (FCL_LIBRARY AND FCL_INCLUDE_DIR)
    find_package_handle_standard_args(fcl DEFAULT_MSG FCL_LIBRARY FCL_INCLUDE_DIR)
else (FCL_LIBRARY AND FCL_INCLUDE_DIR)
    message (STATUS "FCL library not found.  Will download and compile.")

    get_filename_component(CCD_LIBRARY_DIR "${CCD_LIBRARY}" PATH)
    include(ExternalProject)
    # download and build FCL
    ExternalProject_Add(fcl
        DOWNLOAD_DIR "${CMAKE_SOURCE_DIR}/src/external"
        URL "http://downloads.sourceforge.net/project/ompl/dependencies/fcl-0.2.5.tgz"
        URL_MD5 "bdf87f56b7fdc6fb911431c4c68f2b81"
        CMAKE_COMMAND env
        CMAKE_ARGS
            "PKG_CONFIG_PATH=${CCD_LIBRARY_DIR}/pkgconfig"
            "${CMAKE_COMMAND}"
            "-DCMAKE_INSTALL_PREFIX=${CMAKE_BINARY_DIR}/fcl-prefix"
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_CXX_FLAGS=-fPIC"
            "-DFCL_STATIC_LIBRARY=ON"
            "-DCCD_INCLUDE_DIRS=${CCD_INCLUDE_DIR}"
            "-DCCD_LIBRARY_DIRS=${CCD_LIBRARY_DIR}")

    # Make sure ccd exists before building fcl.
    add_dependencies(fcl ccd)

    set(FCL_LIBRARY "${CMAKE_BINARY_DIR}/fcl-prefix/lib/${CMAKE_STATIC_LIBRARY_PREFIX}fcl${CMAKE_STATIC_LIBRARY_SUFFIX}")
    if(EXISTS "${FCL_LIBRARY}")
        set(FCL_LIBRARY "${FCL_LIBRARY}" CACHE FILEPATH "Location of FCL collision checking library" FORCE)
    endif()
    set(FCL_INCLUDE_DIR "${CMAKE_BINARY_DIR}/fcl-prefix/include")
    if(IS_DIRECTORY "${FCL_INCLUDE_DIR}")
        set(FCL_INCLUDE_DIR "${FCL_INCLUDE_DIR}" CACHE PATH "Location of FCL collision checker header files" FORCE)
    endif()
endif (FCL_LIBRARY AND FCL_INCLUDE_DIR)

# Link order is very important here.  If FCL isn't linked first, over-zealous
# optimization may remove needed symbols from CCD in subsequent links.
set(FCL_LIBRARIES ${FCL_LIBRARY} ${CCD_LIBRARY})
