add_library(vertree_context_menu SHARED
  vertree_context_menu.cpp
  vertree_context_menu.rc
)

APPLY_STANDARD_SETTINGS(vertree_context_menu)
target_compile_definitions(vertree_context_menu PRIVATE "NOMINMAX")
target_link_libraries(vertree_context_menu PRIVATE ole32 shell32 shlwapi)
target_link_options(vertree_context_menu PRIVATE
  "/DEF:${CMAKE_CURRENT_SOURCE_DIR}/vertree_context_menu.def"
)

set_target_properties(vertree_context_menu PROPERTIES
  OUTPUT_NAME "vertree_context_menu"
)
