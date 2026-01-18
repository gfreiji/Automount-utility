# AGENTS.md

This file contains guidelines for agentic coding assistants working on this repository.

## Project Overview

A bash utility for macOS that automatically checks and mounts NAS shares (SMB/AFP/NFS) with logging, notifications, and integration with launchd/cron.

## Commands

### Running the Script
```bash
./automount-nas.sh              # Run with default config (~/.automount.conf)
./automount-nas.sh -t           # Test mode: check status without mounting
./automount-nas.sh -d           # Debug mode: verbose output
./automount-nas.sh -c custom.conf  # Use alternate config file
```

### Testing
The project does not have automated tests. Manual testing involves:
- Run script in test mode (`-t`) to check mount status
- Run script in debug mode (`-d`) for verbose logging
- Verify by checking mount status: `mount | grep /Volumes/NAS`
- Check logs: `tail -f ~/Library/Logs/automount-nas.log`

### Linting
Run shellcheck to verify bash script quality:
```bash
shellcheck automount-nas.sh
```

Install shellcheck via homebrew: `brew install shellcheck`

## Code Style Guidelines

### Shebang and Version
- Always start with `#!/bin/bash`
- Target Bash 3.2+ for macOS compatibility
- Include version variable at top level

### Strict Mode
- Enable strict mode with `set -u` at script start (no undefined variables)
- Consider `set -e` for fail-fast behavior (not currently used)

### Variable Naming
- **Constants**: UPPERCASE with underscores (e.g., `NAS_SHARE`, `CONFIG_FILE`)
- **Local variables**: lowercase with underscores (e.g., `mount_point`, `line_count`)
- Declare local variables with `local` keyword in functions

### Quoting
- Double-quote all variable expansions: `"$1"`, `"${NAS_SHARE}"`
- Use `${VAR}` syntax for clarity when variable is part of string
- Quote file paths that may contain spaces

### Function Naming
- Use lowercase with underscores: `log_message`, `is_mounted`, `mount_nas`
- Functions should be descriptive verbs or predicates

### Comments and Documentation
- Use section dividers with `#` repeated:
  ```bash
  ###############################################################################
  # Section Header
  ###############################################################################
  ```
- Inline comments on same line for brief explanations
- Document functions with comments before opening brace
- Include shellcheck directives when sourcing external files:
  ```bash
  # shellcheck source=/dev/null
  source "${CONFIG_FILE}"
  ```

### Error Handling
- Capture command output and exit code separately:
  ```bash
  output=$(command 2>&1)
  result=$?
  ```
- Use `return 0` for success, `return 1` for failure in functions
- Use `exit 0` for success, `exit 1` for failure in main flow
- Log errors before returning/exiting

### Conditional Expressions
- Use `[[ ]]` for string and file tests (modern bash)
- Use `[ ]` only for POSIX compatibility with arithmetic
- Use `-eq`, `-ne` for integer comparisons
- Use `==`, `!=` for string comparisons
- Use `-z` for empty string check, `-n` for non-empty

### Logging
- Use `log_message` function with level: `INFO`, `WARN`, `ERROR`
- Always include context in log messages
- Log before and after critical operations
- Use timestamp format: `date '+%Y-%m-%d %H:%M:%S'`

### Configuration Files
- Use `.example` suffix for template files
- Document required vs optional variables
- Default values defined in script, overridden by sourced config
- Config files use bash variable assignment syntax

### macOS-Specific
- Use `osascript` for notifications
- Use `launchd` plist files for scheduled tasks
- Mount points typically in `/Volumes/`
- Standard log location: `${HOME}/Library/Logs/`
- Use `/usr/local/bin/` for installed scripts

### Security Considerations
- Never log passwords or credentials
- Recommend `chmod 600` for config files with sensitive data
- Avoid passing secrets via command line arguments
- Mention Full Disk Access requirements in documentation

### Exit Codes
- `0`: Success
- `1`: General failure or error
- Non-zero exit codes should be logged

### File Structure
- Main script: `automount-nas.sh`
- Config template: `.automount.conf.example`
- Launchd template: `com.automount.nas.plist.example`
- Documentation: `README.md`
