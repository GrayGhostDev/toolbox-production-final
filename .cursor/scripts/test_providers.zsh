#!/usr/bin/env zsh
set -euo pipefail

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m[ OK ]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }

BASE_OPENAI="${OPENAI_BASE_URL:-https://api.openai.com/v1}"
BASE_ANTHROPIC="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"

OPENAI_KEY="$(security find-generic-password -a "$USER" -s openai_api_key -w 2>/dev/null || true)"
ANTHROPIC_KEY="$(security find-generic-password -a "$USER" -s anthropic_api_key -w 2>/dev/null || true)"

if [[ -z "$OPENAI_KEY" ]]; then
  warn "OpenAI key not found in Keychain (service: openai_api_key)."
else
  info "Querying OpenAI models from $BASE_OPENAI ..."
  curl -sS -H "Authorization: Bearer $OPENAI_KEY" "$BASE_OPENAI/models" | head -n 20 || true
  ok "OpenAI connectivity check attempted."
fi

if [[ -z "$ANTHROPIC_KEY" ]]; then
  warn "Anthropic key not found in Keychain (service: anthropic_api_key)."
else
  info "Querying Anthropic models from $BASE_ANTHROPIC ..."
  curl -sS -H "x-api-key: $ANTHROPIC_KEY" -H "anthropic-version: 2023-06-01" "$BASE_ANTHROPIC/v1/models" | head -n 20 || true
  ok "Anthropic connectivity check attempted."
fi

