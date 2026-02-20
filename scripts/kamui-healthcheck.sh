#!/usr/bin/env bash
set -euo pipefail

CONFIG_DEFAULT="/home/flock_h/daisy/config/mcporter.json"
CONFIG="${MCPORTER_CONFIG:-$CONFIG_DEFAULT}"
RUN_CALL_TEST="${RUN_CALL_TEST:-0}"

ok()   { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
err()  { echo "❌ $*"; }

echo "== Kamui / mcporter healthcheck =="
echo "config: $CONFIG"

# 1) prerequisites
if ! command -v mcporter >/dev/null 2>&1; then
  err "mcporter not found in PATH"
  exit 1
fi
ok "mcporter found: $(mcporter --version)"

if [[ ! -f "$CONFIG" ]]; then
  err "config file not found: $CONFIG"
  exit 1
fi
ok "config file exists"

# 2) env key presence (do not print secret)
if [[ -z "${KAMUI_CODE_PASS_KEY:-}" ]]; then
  err "KAMUI_CODE_PASS_KEY is NOT set in this process context"
  echo "hint: export KAMUI_CODE_PASS_KEY='***'"
  exit 2
fi
KEY_LEN=$(printf "%s" "${KAMUI_CODE_PASS_KEY}" | wc -c | tr -d ' ')
ok "KAMUI_CODE_PASS_KEY is set (length=${KEY_LEN})"

# 3) server list check
LIST_JSON="$(mcporter --config "$CONFIG" list --output json || true)"
if [[ -z "$LIST_JSON" ]]; then
  err "mcporter list returned empty response"
  exit 3
fi

if echo "$LIST_JSON" | grep -q '"status": "error"'; then
  warn "Some servers report error. Summary:"
  echo "$LIST_JSON" | sed -n '1,200p'
  # keep going; maybe only 일부 servers fail
else
  ok "mcporter list reports no server errors"
fi

# 4) optional lightweight call test
if [[ "$RUN_CALL_TEST" == "1" ]]; then
  echo "-- running lightweight call test (t2i sync) --"
  if mcporter --config "$CONFIG" \
    call t2i-kamui-fal-gemini-3-pro-image-preview.gemini_3_pro_image_preview_submit \
    prompt='connectivity test image' num_images=1 aspect_ratio='1:1' sync_mode=true >/tmp/kamui-healthcheck-call.json 2>/tmp/kamui-healthcheck-call.err; then
    ok "call test succeeded"
    echo "result: /tmp/kamui-healthcheck-call.json"
  else
    err "call test failed"
    sed -n '1,120p' /tmp/kamui-healthcheck-call.err || true
    exit 4
  fi
else
  echo "(skip call test) Set RUN_CALL_TEST=1 to execute an actual generation call"
fi

ok "healthcheck finished"
