---
name: serena
description: "Serena code intelligence — LSP-powered symbol navigation, diagnostics, and targeted code surgery. Activate before complex refactors, cross-file analysis, or when graph tools need symbol-level depth."
---

# Serena LSP Code Intelligence

Activate Serena MCP for LSP-powered code intelligence: symbol navigation, type diagnostics, and safe code surgery.

**CRITICAL:** Call `initial_instructions` first when starting any Serena work — it loads the Serena project context.

## Setup & Initialization

1. **Load instructions**: `initial_instructions()`
2. **Activate project**: `activate_project()`
3. **Get overview**: `get_symbols_overview()`

## Tool Capabilities
- `find_symbol`, `find_declaration`, `find_implementations`, `find_referencing_symbols`
- `get_diagnostics_for_file` (type errors, warnings)
- `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`
- `write_memory`, `read_memory`
