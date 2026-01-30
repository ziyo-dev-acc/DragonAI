cmake_minimum_required(VERSION 3.22.1)
project(adaptiveassistant)

option(USE_LLAMA "Enable llama.cpp integration" OFF)

add_library(llama_jni SHARED llama_jni.cpp)

find_library(log-lib log)

target_link_libraries(llama_jni ${log-lib})

# If you add llama.cpp sources under third_party/llama.cpp, set USE_LLAMA=ON
# and link the library here.
