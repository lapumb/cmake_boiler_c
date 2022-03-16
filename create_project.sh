# !/bin/bash

set -e

USAGE="
Description:
    Create a minimal CMake project, in C. 

Usage:
    $0 -n my_awesome_project -d <directory>

Required:
    -n <project_name>     Name of the project

Optional:
    -d <directory>        The directory to create the project in.
                          Defaults to the current directory.
    -h                    Print this help message.

Examples:
    $0 -n 123456
    $0 -n my_awesome_project -d /tmp/my_awesome_project
"

# Default to the current directory
DIRECTORY=`pwd`

# Parse arguments
while getopts ':n:d:' c
do
  case $c in
    n) PROJECT_NAME="$OPTARG";;
    d) DIRECTORY="$OPTARG" ;;
    *)
        echo "$USAGE"
        exit 1
  esac
done

# Make sure the user actually passed a project name prior to moving on
if [ -z "$PROJECT_NAME" ]; then
    echo "You must specify a project name."
    echo "$USAGE"
    exit 1
fi

set -u

# Try to create the directory
mkdir -p "$DIRECTORY"
if [ ! -d "$DIRECTORY" ]; then
    echo "Could not create directory $DIRECTORY"
    exit 1
fi

# code/ level directory definitions
CODE_DIR="$DIRECTORY/code"
INCLUDE_DIR="$CODE_DIR/include"
SRC_DIR="$CODE_DIR/src"
COMPONENTS_DIR="$CODE_DIR/components"

# code/components/ level directory definitions
DUMMY_LIB_DIR="$COMPONENTS_DIR/dummy"
DUMMY_INCLUDE="$DUMMY_LIB_DIR/include"
DUMMY_PRIV_INCLUDE="$DUMMY_LIB_DIR/priv_include"
DUMMY_SRC="$DUMMY_LIB_DIR/src"

# tools/ level directory definitions
TOOLS_DIR="$DIRECTORY/tools"

create_dirs() {
    # code/ level directories
    mkdir -p "$INCLUDE_DIR"
    mkdir -p "$SRC_DIR"
    mkdir -p "$COMPONENTS_DIR"

    # code/components/ level directories
    mkdir -p "$DUMMY_LIB_DIR"
    mkdir -p "$DUMMY_INCLUDE"
    mkdir -p "$DUMMY_PRIV_INCLUDE"
    mkdir -p "$DUMMY_SRC"

    # tools/ level directories
    mkdir -p "$TOOLS_DIR/cmake"
}

create_dummy_component() {
    # Create the dummy public header
    DUMMY_LIB_HEADER="""#pragma once 

void dummy_function(void);"""
    echo "$DUMMY_LIB_HEADER" > "$DUMMY_INCLUDE/dummy.h"

    # Create the dummy private header
    DUMMY_LIB_PRIV_HEADER="""#pragma once 

void dummy_important_function(void);"""
    echo "$DUMMY_LIB_PRIV_HEADER" > "$DUMMY_PRIV_INCLUDE/dummy_priv.h"

    # Create the dummy source
    DUMMY_LIB_SRC_FILE="""#include \"dummy.h\"
#include \"dummy_priv.h\"

#include <stdio.h>

void dummy_function(void) {
    printf(\"dummy_function\\\n\");
}

void dummy_important_function(void) {
    printf(\"void dummy_important_function\\\n\");
}"""
    echo "$DUMMY_LIB_SRC_FILE" > "$DUMMY_SRC/dummy.c"

    # Create the dummy CMakeLists.txt file
    DUMMY_CMAKE_LIST="""project(dummy)

file(GLOB SRCS src/*.c)
add_library(\${PROJECT_NAME} STATIC
    \${SRCS}
)

target_link_libraries(\${PROJECT_NAME}
    
)

target_include_directories(\${PROJECT_NAME} PUBLIC
$<BUILD_INTERFACE:\${CMAKE_CURRENT_SOURCE_DIR}/include>
)

target_include_directories(\${PROJECT_NAME} PRIVATE
$<BUILD_INTERFACE:\${CMAKE_CURRENT_SOURCE_DIR}/priv_include>
)

include(../../../tools/cmake/extra_warnings.cmake)"""
    echo "$DUMMY_CMAKE_LIST" > "$DUMMY_LIB_DIR/CMakeLists.txt"
}

create_proj_files() {
    # Create the code/include file
    INCLUDE_MAIN="""#pragma once

void ${PROJECT_NAME}_hello_world(void);"""
    echo "$INCLUDE_MAIN" > "$INCLUDE_DIR/${PROJECT_NAME}_main.h"

    # Create the code/src file
    SRC_MAIN="""#include \"${PROJECT_NAME}_main.h\"
#include <dummy.h>

#include <stdio.h>
#include <stdio.h>

void ${PROJECT_NAME}_hello_world(void) {
    dummy_function();
    printf(\"Hello World!\\\n\");
}

int main(void) {
    ${PROJECT_NAME}_hello_world();
    return 0;
}"""
    echo "$SRC_MAIN" > "$SRC_DIR/${PROJECT_NAME}_main.c"

    # Create the code/CMakeLists.txt file
    CODE_CMAKELISTS="""cmake_minimum_required(VERSION 3.10)

project(\"${PROJECT_NAME}\")
set(VERSION \"0.0.1\")

add_subdirectory(components/dummy)

file(GLOB SRCS src/*.c)
add_executable(\${PROJECT_NAME}
    \${SRCS}
)

target_include_directories(\${PROJECT_NAME} PRIVATE
    \${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(\${PROJECT_NAME}
    dummy
)

include(../tools/cmake/extra_warnings.cmake)"""
    echo "$CODE_CMAKELISTS" > "$DIRECTORY/code/CMakeLists.txt"
}

create_clean_build_run_scripts() {
    CLEAN="""#!/bin/bash

set -e

echo \"Cleaning..\"
rm -rf build"""
    echo "$CLEAN" > "$DIRECTORY/code/clean.sh"
    chmod +x "$DIRECTORY/code/clean.sh"

    BUILD="""# !/bin/bash

set -e

mkdir -p build
cd build

echo \"Building..\"

cmake ..
make"""
    echo "$BUILD" > "$CODE_DIR/build.sh"
    chmod +x "$CODE_DIR/build.sh"

    RUN="""#!/bin/bash

set -e

./build/$PROJECT_NAME"""
    echo "$RUN" > "$CODE_DIR/run.sh"
    chmod +x "$CODE_DIR/run.sh"
}

create_cmake_extra_flags() {
    CMAKE_EXTRA_FLAGS="""# A strict set of compilation flags.
list(APPEND EXTRA_C_FLAGS_LIST
    -Wall
    -Werror
    -Wextra
    -Wpedantic
    -Wunused-function
    -Wunused-but-set-variable
    -Wunused-variable
    -Wdeprecated-declarations
    -Wunused-parameter
    -Wsign-compare
    -Wold-style-declaration

    # Stop on first error
    -Wfatal-errors

    # Misc. other flags
    # Used these links for insipiration:
    # https://stackoverflow.com/a/3376483
    # https://interrupt.memfault.com/best-and-worst-gcc-clang-compiler-flags
    -fno-common
    -Wshadow
    -Wpointer-arith
    -Wcast-align
    -Wstrict-prototypes
    -Wwrite-strings
    -Wswitch-default
    -Wunreachable-code
    -Wformat=2
    -Winit-self
    -Wformat-truncation
)
target_compile_options(\${PROJECT_NAME} PRIVATE \${EXTRA_C_FLAGS_LIST})"""
    echo "$CMAKE_EXTRA_FLAGS" > "$TOOLS_DIR/cmake/extra_warnings.cmake"
}

create_gitignore() {
    GITIGNORE="""
# Created by https://www.toptal.com/developers/gitignore/api/c
# Edit at https://www.toptal.com/developers/gitignore?templates=c

### C ###
# Prerequisites
*.d

# Object files
*.o
*.ko
*.obj
*.elf

# Linker output
*.ilk
*.map
*.exp

# Precompiled Headers
*.gch
*.pch

# Libraries
*.lib
*.a
*.la
*.lo

# Shared objects (inc. Windows DLLs)
*.dll
*.so
*.so.*
*.dylib

# Executables
*.exe
*.out
*.app
*.i*86
*.x86_64
*.hex

# Debug files
*.dSYM/
*.su
*.idb
*.pdb

# Kernel Module Compile Results
*.mod*
*.cmd
.tmp_versions/
modules.order
Module.symvers
Mkfile.old
dkms.conf

# End of https://www.toptal.com/developers/gitignore/api/c"""
    echo "$GITIGNORE" > "$DIRECTORY/.gitignore"
}

create_readme() {
    README="""# ${PROJECT_NAME}

TODO: Fill in the README. 

Happy coding :)"""
    echo "$README" > "$DIRECTORY/README.md"
}

# Main script
create_dirs
create_dummy_component
create_proj_files
create_clean_build_run_scripts
create_cmake_extra_flags
create_gitignore
create_readme