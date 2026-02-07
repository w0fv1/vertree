add_executable(vertree_context_menu WIN32
  vertree_context_menu.cpp
)

APPLY_STANDARD_SETTINGS(vertree_context_menu)
target_compile_definitions(vertree_context_menu PRIVATE "NOMINMAX")
target_link_libraries(vertree_context_menu PRIVATE ole32 shell32 shlwapi)

set_target_properties(vertree_context_menu PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "$<TARGET_FILE_DIR:vertree>"
  OUTPUT_NAME "vertree_context_menu"
)

install(TARGETS vertree_context_menu RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
