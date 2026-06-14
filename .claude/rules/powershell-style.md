---
globs: ["*.ps1", "*.psm1", "*.psd1"]
---

# PowerShell style

## Formatting

- Indentation: **4 spaces**
- Brace style: **OTBS** - opening `{` on same line as statement, closing `}` on its own line, block body always on separate lines
- For conditional/loop statements with multiple conditions, all conditions and the opening `{` must be on the same line
- Use ternary `? :` for simple true/false; `switch` with `continue` for range/complex conditions; `if/elseif/else` for distinct paths

## Naming

- Functions: `Verb-Noun` PascalCase (approved verbs only - `Get-Verb` for the list)
- Parameters: `PascalCase`; local variables: `camelCase`
- Script-scoped variables: `$script:varName` for state shared across function boundaries (`wsl_setup.ps1` uses `$Script:rel_*` to cache release versions across distro loops)
- Public functions require comment-based help: `.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`

## Parameters

- Use `[Parameter(Mandatory, Position = 0)]` for required positional parameters
- Use `[Alias('s')]` for short parameter aliases (single letter)
- Use `[ValidateSet(...)]` for enums, `[ValidateNotNullOrEmpty()]` for required strings, `[ValidateScript({ ... })]` for complex validation
- Switches are never mandatory
- Use parameter splatting for >3 parameters; cast switches to bool when passing: `-WebDownload ([bool]$WebDownload)`
- Use `[Parameter(ParameterSetName = 'X')]` with `[CmdletBinding(DefaultParameterSetName = 'Y')]` for mutually exclusive parameter groups

## Error handling

- Set `$ErrorActionPreference = 'Stop'` in `begin` block
- Use specific exception types in catch blocks before generic catch-all
- Check `$LASTEXITCODE` immediately after external command invocations (`wsl.exe`, `git`, native binaries)
- **Guard native binaries that may not exist on the host.** Cross-platform scripts (Windows host + Linux/WSL guest) cannot assume `ssh`, `git`, `gh`, etc. are on PATH. Use `Get-Command <name> -ErrorAction SilentlyContinue` before invoking, and provide a fallback. See `design/lessons.md` (commit `dfb5943`).

## Strings

- Prefer `-f` format operator for simple interpolations: `'{0}: {1}' -f $name, $value`
- Use `[string]::Join()` for complex multi-part strings (output formatting, shell commands)
- Never use `+` operator for string concatenation
- Normalize line endings with `.Replace("\`r\`n", "\`n")` for cross-platform (Windows/Linux) consistency - `wsl.exe` output crosses this boundary
- ANSI colors via escape sequences: `` `e[32m `` (green), `` `e[31;1m `` (bold red), `` `e[0m `` (reset)

## Collections

- Use `[System.Collections.Generic.List[T]]` for ordered collections that grow
- Use `[System.Collections.Generic.SortedSet[T]]` for unique items with automatic sorting
- Use `[System.Collections.Generic.HashSet[T]]` for deduplication and O(1) lookups
- Never use non-generic `System.Collections` classes
- Pipe `.Add()` calls to `| Out-Null` to suppress return value
- Use `.ForEach({ ... })` method for pipeline expressions; `foreach` keyword for iteration with `break`/`continue`

## Output and return

- Use `Write-Host` for colored/formatted console output (bypasses pipeline)
- Return `$null` explicitly when conditional logic skips operations
- Use `Write-Output -NoEnumerate` when returning empty arrays to prevent pipeline unwrapping `@()` to `$null`

## WSL-specific (wsl/*.ps1)

- Use direct `wsl.exe @args` with argument splatting for distribution commands
- Build wsl arguments in `[System.Collections.Generic.List[string]]`, modify in-place for subsequent calls
- Always set `$psi.UseShellExecute = $false` and `$psi.WorkingDirectory = $PWD.Path` for `Process.Start`
- Normalize captured `wsl.exe` output with `.Replace("\`r\`n", "\`n")` - the boundary between Windows and Linux line endings is the most common source of bugs in this layer

## Module imports

- Use `Push-Location "$PSScriptRoot/.."` in `begin` block to set directory context
- Import with `Import-Module (Resolve-Path './modules/<name>') -Force` or `Convert-Path`
- Re-export public functions from the module manifest (`<module>.psd1` → `FunctionsToExport`)
