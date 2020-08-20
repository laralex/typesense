# Download and build Firebase

set(FIREBASE_VERSION 6.11.0)
set(FIREBASE_NAME firebase-cpp-sdk-${FIREBASE_VERSION})
set(FIREBASE_TAR_PATH ${DEP_ROOT_DIR}/${FIREBASE_NAME}.tar.gz)

if(NOT EXISTS ${FIREBASE_TAR_PATH})
    message(STATUS "Downloading ${FIREBASE_NAME}...")
    file(DOWNLOAD https://github.com/firebase/firebase-cpp-sdk/archive/v${FIREBASE_VERSION}.tar.gz ${FIREBASE_TAR_PATH})
endif()

if(NOT EXISTS ${DEP_ROOT_DIR}/${FIREBASE_NAME})
    message(STATUS "Extracting ${FIREBASE_NAME}...")
    execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${FIREBASE_TAR_PATH} WORKING_DIRECTORY ${DEP_ROOT_DIR}/)
endif()

if(NOT EXISTS ${DEP_ROOT_DIR}/${FIREBASE_NAME}/build/auth/libfirebase_auth.a)
    message("Configuring ${FIREBASE_NAME}...")
    file(MAKE_DIRECTORY ${DEP_ROOT_DIR}/${FIREBASE_NAME}/build)
    execute_process(COMMAND ${CMAKE_COMMAND}
            "-DCMAKE_FIND_LIBRARY_SUFFIXES=.a"
            "-H${DEP_ROOT_DIR}/${FIREBASE_NAME}"
            "-B${DEP_ROOT_DIR}/${FIREBASE_NAME}/build"
            RESULT_VARIABLE
            FIREBASE_CONFIGURE)
    if(NOT FIREBASE_CONFIGURE EQUAL 0)
        message(FATAL_ERROR "${FIREBASE_NAME} configure failed!")
    endif()

    if(BUILD_DEPS STREQUAL "yes")
        message("Building ${FIREBASE_NAME} locally (only firebase_auth)...")
        execute_process(COMMAND ${CMAKE_COMMAND} --build
                "${DEP_ROOT_DIR}/${FIREBASE_NAME}/build"
				--target firebase_auth
				RESULT_VARIABLE FIREBASE_BUILD)
        if(NOT FIREBASE_BUILD EQUAL 0)
            message(FATAL_ERROR "${FIREBASE_NAME} build (firebase_auth) failed!")
        endif()
    endif()
endif()
