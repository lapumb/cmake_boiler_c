# CMake Boiler (C)

This repository contains a simple script to instantiate a standard CMake project (in C).

The script in this directory ([`create_project.sh`](./create_project.sh)) will create the following tree:

```bash
 |-.gitignore
 |-code
 | |-build.sh
 | |-clean.sh
 | |-CMakeLists.txt
 | |-components
 | | |-dummy
 | | | |-CMakeLists.txt
 | | | |-include
 | | | | |-dummy.h
 | | | |-priv_include
 | | | | |-dummy_priv.h
 | | | |-src
 | | | | |-dummy.c
 | |-include
 | | |-test_main.h
 | |-run.sh
 | |-src
 | | |-test_main.c
 |-README.md
 |-tools
 | |-cmake
 | | |-extra_warnings.cmake
```

# Prerequisites

## Install CMake

To build a CMake project, you have to have CMake installed. See [CMake Install](https://cmake.org/install/) for more information.

## Miscellaneous

To utilize this repository, you must be in an environment that can run a bash script. This can be done from the default Linux and MacOS terminals. 

On Windows, you can run `wsl` or `bash` to get into the bash environment.

# Generating a Project

To generate a new CMake project in a new directory `my_directory`, you can run the following command:

```bash
sh create_project.sh -d my_directory -n my_project
```

Or, to create a new CMake project in the current directory, you can run the following command:

```bash
sh create_project.sh -n my_project
```

# Help

To see the usage of this script, run the following command:

```bash
sh create_project.sh -h
```