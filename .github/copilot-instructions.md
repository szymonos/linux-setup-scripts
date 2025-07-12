# Repository Scoped instructions.

## Enforcement
- Consider ALL guidelines as mandatory requirements unless explicitly stated otherwise
- Follow ALL guidelines in ALL code modifications without requiring explicit reminders
- Flag any potential violations of these guidelines in your responses
- If existing code doesn't meet these standards, update it when modifying related sections

---
applyTo: "**/*.ps1"
---
## PowerShell Coding Standards

### Formatting and Style
- Target PowerShell 7.4+ for all scripts and modules
- Ensure all code is cross-platform and testable on Linux
- Prefer cmdlets and language features available in PowerShell Core
- Use parameter splatting for functions with more than 3 parameters
- Always include comment-based help with `.SYNOPSIS`, `.PARAMETER`, and `.EXAMPLE` sections
- Use `Get-Help` compatible documentation for all public functions
- Use One True Brace Style (OTBS) formatting style for readability
  All conditional and loop blocks (if, elseif, else, foreach, while, for) must use:
  - The opening brace `{` must be on the same line as the statement.
  - For all conditional or loop statement with multiple conditions, all conditions and the opening brace { must be on the same line as the statement, regardless of length.
  - The closing brace `}` must be on its own line.
  - The block body must always be on separate lines, never inline with the condition.
- Write arrays whose line exceeds 120 characters on its own line, enclosed in `@(...)` with one element per line for readability.

### Naming Conventions
- Use Verb-Noun format for function names and use only approved verbs from the PowerShell approved verb list.
- Use PascalCase for functions, cmdlets and scripts/functions parameter variables.
- Use camelCase for locally scoped variables and properties.

### Function Design
- Functions should have a single responsibility
- Handle errors with appropriate exception handling
- Use consistent error messaging patterns

---
applyTo: "**/*.sh"
---
## Bash scripts Coding Standards

### Formatting and Style
- Target Bash 5.0+ for all scripts
- Ensure all code is POSIX-compliant where possible and cross-distro compatible
- Use `#!/usr/bin/env bash` as the shebang
- Indent with 2 spaces, no tabs
- Keep line length ≤ 120 characters
- Use `set -euo pipefail` for robust error handling unless explicitly not desired
- Place spaces around operators and after commas
- Use `$(...)` for command substitution, not backticks
- Always quote variable expansions, especially in command arguments (`"$var"`)
- Use one blank line between functions and major code blocks
- Place function definitions at the top of the script where practical
- Use all-lowercase for local variables, all-uppercase for environment/config constants
- Use arrays for lists, avoid word splitting
- Prefer `local` for function-scoped variables

### Naming Conventions
- Use snake_case for function and variable names
- Use descriptive names for functions and variables
- Prefix private/helper functions with `_`
- Use all-uppercase with underscores for constants

### Function Design
- Each function should have a single responsibility
- Include a brief comment above each function describing its purpose
- Use `return` or exit codes for error signaling, not `echo`
- Avoid global variables unless necessary
- Pass parameters explicitly to functions
- Use `"$@"` to forward all arguments when wrapping commands
- Document script usage and parameters at the top of the file
