set(LLVM_OBJECT_DIR "${PROJECT_BINARY_DIR}/llvm")

add_custom_command(
  OUTPUT ${LLVM_OBJECT_DIR}
  COMMAND ${CMAKE_COMMAND} -E make_directory ${LLVM_OBJECT_DIR}
)

foreach(LLVM_LIB ${LLVM_AVAILABLE_LIBS} ${CLANG_LIBRARIES})
  get_filename_component(LLVM_LIB_NAME "${LLVM_LIB}" NAME)
  execute_process(
    COMMAND ${CMAKE_AR} t ${LLVM_LIB}
    OUTPUT_VARIABLE LLVM_LIB_CONTENTS)
  string(REGEX MATCHALL "[^\n]+" LLVM_LIB_OBJECT_BASENAMES "${LLVM_LIB_CONTENTS}")
  foreach(LLVM_OBJECT ${LLVM_OBJECT_BASENAMES})
    list(APPEND LLVM_OBJECTS "${LLVM_OBJECT_DIR}/${LLVM_LIB_NAME}/${LLVM_OBJECT}")
  endforeach()
  add_custom_command(
    OUTPUT "${LLVM_OBJECT_DIR}/${LLVM_LIB_NAME}"
    DEPENDS ${LLVM_OBJECT_DIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${LLVM_OBJECT_DIR}/${LLVM_LIB_NAME}"
  )
  add_custom_command(
    OUTPUT ${LLVM_OBJECTS}
    DEPENDS ${LLVM_LIB} "${LLVM_OBJECT_DIR}/${LLVM_LIB_NAME}"
    COMMAND ${CMAKE_AR} x ${LLVM_LIB}
    WORKING_DIRECTORY "${LLVM_OBJECT_DIR}/${LLVM_LIB_NAME}"
  )
  list(APPEND ALL_LLVM_OBJECTS ${LLVM_OBJECTS})
endforeach()

add_custom_target(
  LLVMObjectFiles
  DEPENDS ${ALL_LLVM_OBJECTS}
)
