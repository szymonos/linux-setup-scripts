---
globs: ["*.sh", "*.bash", "*.bats", "*.zsh"]
---

# Bash style

- Shebang: `#!/usr/bin/env bash`
- Indentation: **2 spaces**; line length: **120 chars max**
- Error handling: `set -euo pipefail` for executable scripts. For files dot-sourced into the user's shell (`.assets/config/bash_cfg/*.sh`, anything installed to `/etc/profile.d/`), drop `-u` - `nounset` breaks shell-init files that source optional vars from the environment.
- Command substitution: `$(...)`, never backticks
- Functions: `snake_case`, private: `_prefixed`; prefer `local` for function-scoped variables
- Variables: `snake_case` locals, `UPPERCASE` constants/env
- Color output: `\e[31;1m` red/error, `\e[32m` green, `\e[92m` bright green, `\e[96m` cyan/info

## Cross-platform regex

BSD `grep`/`sed` (macOS) and GNU `grep`/`sed` (Linux) disagree on edge cases. Anything sourced from `.assets/config/bash_cfg/` may run on a macOS host during contributor dev loops.

- Never use empty-alternative regex: `(|foo|bar)` - BSD silently fails to match the empty alternative. Use `(foo|bar)?` instead.
- Prefer BSD-compatible sed: `sed -En` (not `-rn`), no `\s`/`\w`/`\d` shorthand, no `-P` (perl-regex).
- `grep -E` (ERE) is portable; `grep -P` (PCRE) is GNU-only.

See `design/lessons.md` for the BSD-grep incident (commit `78b177d`).

## POSIX guard for `/etc/profile.d/`

Any file installed into `/etc/profile.d/` is sourced by dash (Debian/Ubuntu `/bin/sh`) during login. dash chokes on bash syntax (`function` keyword, arrays, `[[ ]]`). Start the file with:

```bash
[ -n "${BASH_VERSION:-}${ZSH_VERSION:-}" ] || return 0
```

Verify with `dash -c '. <file>'`. See `design/lessons.md` (commit `58649ce`).

## zsh compatibility

Files under `.assets/config/bash_cfg/` are sourced from both bash and zsh user shells. The `check-zsh-compat` pre-commit hook parses each one under zsh. Common pitfalls:

- `[[ $arr[@] ]]` - arrays are 1-indexed in zsh, 0-indexed in bash.
- Word splitting on unquoted `$var` - zsh doesn't split by default; explicit `${(s: :)var}` or quote consistently.
- `local` outside a function - bash errors loudly, zsh warns silently.

## Common patterns

```bash
# Distro detection
SYS_ID="$(sed -En '/^ID.*(alpine|arch|fedora|debian|ubuntu|opensuse).*/{s//\1/;p;q}' /etc/os-release)"

# Root check
if [ $EUID -ne 0 ]; then
  printf '\e[31;1mRun the script as root.\e[0m\n' >&2
  exit 1
fi
```
