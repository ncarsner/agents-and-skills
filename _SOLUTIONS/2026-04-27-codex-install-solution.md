# Codex CLI Installation Fix (2026-04-27)

## The Issue
When trying to run `codex` in the terminal, the system returned `command not found`. 

Although the command was present in the system path (`/opt/homebrew/bin/codex`), it was a **broken symbolic link**. It pointed to a binary file in the Homebrew Caskroom that had been deleted or moved, making the command unusable.

## Key Files & Locations
- **Binary Link:** `/opt/homebrew/bin/codex`
- **Actual Binary:** `/opt/homebrew/Caskroom/codex/0.125.0/codex-aarch64-apple-darwin`
- **Configuration:** `~/.codex/config.toml`

## Before & After States

### Before
- `/opt/homebrew/bin/codex` -> (Points to non-existent file)
- `codex --version` -> `zsh: command not found: codex`

### After
- `/opt/homebrew/bin/codex` -> `/opt/homebrew/Caskroom/codex/0.125.0/codex-aarch64-apple-darwin` (Valid link)
- `codex --version` -> `codex-cli 0.125.0` (Working)

## Quick Troubleshooting Guide

If `codex` is missing or not working:

1. **Check the link:**
   Run `ls -l /opt/homebrew/bin/codex`. If it highlights in red or says "broken link", it needs to be fixed.

2. **Verify installation status:**
   Run `brew info --cask codex`.

3. **The Fix:**
   Force a re-link and re-download by running:
   ```bash
   brew reinstall --cask codex
   ```

4. **Verify:**
   ```bash
   codex --version
   ```
