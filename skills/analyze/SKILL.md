---
name: analyze
description: "Scan and index an existing codebase using codebase-memory-mcp (knowledge graph) and serena (LSP symbol intelligence) to build a structural knowledge graph, symbol index, and domain context in devflow/CONTEXT.md."
---

# Codebase Analysis & Indexing (/devflow:analyze)

Use this skill when onboarding to an existing codebase, when exploring unfamiliar code, or when the user invokes `/devflow:analyze`.

It coordinates **`codebase-memory-mcp`** (knowledge graph, architecture clusters, hub/bridge analysis) and **`serena`** (LSP symbol extraction, callers, type diagnostics) to deeply understand the architecture without burning tokens on brute-force file scanning.

**Announce at start:** "🔍 /devflow:analyze — Indexing codebase with codebase-memory-mcp & serena..."

---

## 🛠️ Step-by-Step Workflow

### Step 1: Structural Knowledge Graph Indexing (`codebase-memory-mcp`)

1. **Check Index Status or Trigger Indexing**:
   - Call `codebase-memory-mcp:index_status` or `codebase-memory-mcp:index_repository`.
   - Ensure the repository is indexed locally.

2. **Extract Architecture & Topology**:
   - Call `codebase-memory-mcp:get_architecture` to understand directory clustering and community structures.
   - Call `codebase-memory-mcp:search_graph` to locate core services, repositories, controllers, or entry points.
   - Identify hub nodes and bridge files (high blast-radius areas).

---

### Step 2: LSP Symbol Navigation & Memory (`serena`)

1. **Initialize Serena**:
   - Call `serena:initial_instructions` (or `mcp__serena__initial_instructions`) to bootstrap Serena's project context.
   - Call `serena:activate_project` (or `mcp__serena__activate_project`).

2. **Extract Top-Level Symbols Overview**:
   - Call `serena:get_symbols_overview` (or `mcp__serena__get_symbols_overview`) to get top-level classes, methods, and types.
   - For key symbols identified in Step 1, call `serena:find_referencing_symbols` to see callers and call sites.

3. **Check Diagnostics (if applicable)**:
   - If analyzing specific problematic files, call `serena:get_diagnostics_for_file` for IDE-level error detection.

---

### Step 3: Synthesize Knowledge into `devflow/CONTEXT.md`

Always generate or update `devflow/CONTEXT.md` with the extracted structural intelligence:

```markdown
# Project Context & Domain Model

## 1. System Overview & Tech Stack
- **Framework/Runtime**: [e.g. Laravel 11 / PHP 8.3 / MySQL]
- **Key Dependencies**: [e.g. Sanctum, Pest, Tailwind]

## 2. Ubiquitous Domain Vocabulary (Glossary)
- **<Concept A>**: [Definition, role in domain]
- **<Concept B>**: [Definition, role in domain]

## 3. Core Architecture & Module Boundaries
- **Entry Points**: [HTTP Controllers / Console Commands / Jobs]
- **Domain/Service Layer**: [Services, Actions, Repositories]
- **Data Models**: [Eloquent Models, DB Schema entities]

## 4. Hub & Bridge Files (High Blast Radius)
- `path/to/HubFile.php`: [Why it is critical, dependencies count]

## 5. Verification & Test Seams
- **Test Runner**: `php artisan test` (or `npm test`, `pytest`)
- **Key Test Files**: `tests/Feature/...`, `tests/Unit/...`
```

---

### Step 4: Execution Handoff

After generating/updating `devflow/CONTEXT.md`, summarize the architectural findings concisely (2-4 bullet points) and offer the next step:

1. **Grill on Feature/Refactor**: "Proceed to `/devflow:clarify-requirements` or `/devflow:clarify-requirements` to clarify new requirements."
2. **Implementation Planning**: "Proceed to `/devflow:write-plan` to plan out tasks."
