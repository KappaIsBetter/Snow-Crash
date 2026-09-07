# Level03

Just like before, we can't just access the flag file :
```bash
ls -ld /home/flag03
drwxr-x--- 2 flag03 flag03 4096 Jun  9 19:03 /home/flag03
```

We also check again for an application in /opt/snowcrash :
```bash
$ ls /opt/snowcrash/level03
CMakeLists.txt
```

We see an app lets see this file :
```bash
cmake_minimum_required(VERSION 3.20)

# Build configuration matrix
set(BURBCLAVE_SECURITY_LEVEL    "enhanced")
set(BURBCLAVE_RUNTIME_VERSION   "3.0.0-stable")
set(BURBCLAVE_LOG_FACILITY      "syslog")
set(BURBCLAVE_AUDIT_TRAIL       ON)
set(BURBCLAVE_CRYPTO_BACKEND    "aes256-gcm")
set(BURBCLAVE_MAX_SESSIONS      64)
set(BURBCLAVE_SOCKET_PATH       "/var/run/burbclave.sock")
set(BURBCLAVE_STATE_DIR         "/var/lib/burbclave")
set(BURBCLAVE_CONFIG_SCHEMA_VERSION 2)
set(BURBCLAVE_KEEPALIVE_INTERVAL 30)
set(BURBCLAVE_RETRY_LIMIT        5)
set(BURBCLAVE_WATCHDOG_TIMEOUT   120)

# Compiler capability detection
set(HAVE_STACK_PROTECTOR TRUE)
set(HAVE_FORTIFY_SOURCE TRUE)
set(HAVE_PIE TRUE)
set(HAVE_CF_PROTECTION FALSE)

# Install layout

# Build-type gate
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    set(BURBCLAVE_OPTIMIZE_FLAGS "-O2 -DNDEBUG")
    set(BURBCLAVE_STRIP_SYMBOLS ON)
elseif(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(BURBCLAVE_OPTIMIZE_FLAGS "-O0 -g3")
    set(BURBCLAVE_STRIP_SYMBOLS OFF)
else()
    set(BURBCLAVE_OPTIMIZE_FLAGS "-O1")
    set(BURBCLAVE_STRIP_SYMBOLS OFF)
endif()

# Audit-trail verbosity control
if(BURBCLAVE_AUDIT_TRAIL)
    set(BURBCLAVE_LOG_FLAGS "-DENABLE_AUDIT=1 -DLOG_FACILITY=${BURBCLAVE_LOG_FACILITY}")
else()
    set(BURBCLAVE_LOG_FLAGS "-DENABLE_AUDIT=0")
endif()

# Security level determines link flags
if(BURBCLAVE_SECURITY_LEVEL STREQUAL "enhanced")
    set(BURBCLAVE_LINK_FLAGS "-Wl,-z,relro,-z,now")
elseif(BURBCLAVE_SECURITY_LEVEL STREQUAL "strict")
    set(BURBCLAVE_LINK_FLAGS "-Wl,-z,relro,-z,now,-z,noexecstack")
else()
    set(BURBCLAVE_LINK_FLAGS "")
endif()

# Platform consistency check
if(NOT CMAKE_SYSTEM_NAME STREQUAL "Linux")
    message(WARNING "BurbclaveRuntime is only validated on Linux")
endif()

# Session limit bounds check
if(BURBCLAVE_MAX_SESSIONS LESS 1 OR BURBCLAVE_MAX_SESSIONS GREATER 1024)
    message(FATAL_ERROR "BURBCLAVE_MAX_SESSIONS out of range [1, 1024]")
endif()

file(READ "/etc/burbclave/burbclave.conf" CONF_CONTENT)

string(REGEX MATCH "runtime_base=([^\n]+)" _ ${CONF_CONTENT})
set(RUNTIME_BASE ${CMAKE_MATCH_1})

string(REGEX MATCH "workspace=([^\n]+)" _ ${CONF_CONTENT})
set(WORKSPACE_NAME ${CMAKE_MATCH_1})

string(CONCAT RESOLVED_BUILD_PATH "${RUNTIME_BASE}" "/" "${WORKSPACE_NAME}")

include(${RESOLVED_BUILD_PATH}/build.cmake)

```
Important part :

```bash
file(READ "/etc/burbclave/burbclave.conf" CONF_CONTENT)

string(REGEX MATCH "runtime_base=([^\n]+)" _ ${CONF_CONTENT})
set(RUNTIME_BASE ${CMAKE_MATCH_1})

string(REGEX MATCH "workspace=([^\n]+)" _ ${CONF_CONTENT})
set(WORKSPACE_NAME ${CMAKE_MATCH_1})

string(CONCAT RESOLVED_BUILD_PATH "${RUNTIME_BASE}" "/" "${WORKSPACE_NAME}")

```
