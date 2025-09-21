#!/usr/bin/env zsh
set -euo pipefail

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*"; }

info "This script securely stores your AI provider keys in macOS Keychain and wires them into Cursor."
info "No keys are printed. Press Enter to skip a provider."

# Prompt for OpenAI key (hidden input)
OPENAI_API_KEY=""
printf "Enter OpenAI API Key (hidden, press Enter to skip): "
stty -echo; IFS= read -r OPENAI_API_KEY; stty echo; printf "\n"
if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  security add-generic-password -a "$USER" -s openai_api_key -U -w "$OPENAI_API_KEY" >/dev/null
  ok "Stored OpenAI key in Keychain (service: openai_api_key)."
else
  warn "Skipped OpenAI key."
fi

# Prompt for Anthropic key (hidden input)
ANTHROPIC_API_KEY=""
printf "Enter Anthropic API Key (hidden, press Enter to skip): "
stty -echo; IFS= read -r ANTHROPIC_API_KEY; stty echo; printf "\n"
if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
  security add-generic-password -a "$USER" -s anthropic_api_key -U -w "$ANTHROPIC_API_KEY" >/dev/null
  ok "Stored Anthropic key in Keychain (service: anthropic_api_key)."
else
  warn "Skipped Anthropic key."
fi

# Clear variables from current shell
unset -v OPENAI_API_KEY || true
unset -v ANTHROPIC_API_KEY || true

# Export keys to GUI environment (for Cursor launched from Dock)
if security find-generic-password -a "$USER" -s openai_api_key -w >/dev/null 2>&1; then
  launchctl setenv OPENAI_API_KEY "$(security find-generic-password -a "$USER" -s openai_api_key -w)"
  ok "Exported OPENAI_API_KEY to GUI environment."
fi
if security find-generic-password -a "$USER" -s anthropic_api_key -w >/dev/null 2>&1; then
  launchctl setenv ANTHROPIC_API_KEY "$(security find-generic-password -a "$USER" -s anthropic_api_key -w)"
  ok "Exported ANTHROPIC_API_KEY to GUI environment."
fi

# Append to ~/.zshrc to load keys from Keychain for terminal shells
ZSHRC="$HOME/.zshrc"
PATCH_MARK="# === Cursor AI keys via Keychain (do not print) ==="
if ! grep -Fq "$PATCH_MARK" "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "$PATCH_MARK"
    echo 'export OPENAI_API_KEY=$(security find-generic-password -a "$USER" -s openai_api_key -w)'
    echo 'export ANTHROPIC_API_KEY=$(security find-generic-password -a "$USER" -s anthropic_api_key -w)'
  } >> "$ZSHRC"
  ok "Added Keychain-backed exports to $ZSHRC"
else
  info "Keychain-backed exports already present in $ZSHRC"
fi

info "Done. If Cursor is open, use: Developer: Reload Window."

