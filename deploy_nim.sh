#!/usr/bin/env bash
# === Utility ===
# NOTE: Use %b (not %s) so embedded \n sequences render as real newlines.
log() { printf "\033[1;32m[INFO]\033[0m %b\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %b\n" "$*"; }
err() { printf "\033[1;31m[ERROR]\033[0m %b\n" "$*" >&2; }
suggest_fix() { printf "\033[1;36m[SUGGESTION]\033[0m %b\n" "$*"; }
die() {
  show_help
  err "$*"
  echo
  exit 1
}

# === Phase 6: Deploy NIM ===
# USAGE:
# source ./deploy_nim.sh && deploy_nim meta llama-3.1-8b-instruct-dgx-spark 1.0.0-variant

deploy_nim() {
  local nim_api_namespace="${1:?namespace required}"
  local nim_name="${2:?name required}"
  local image_tag="${3:?tag required}"

  log "Requesting deployment of $nim_name NIM..."

  local body http
  body="$(curl -sS -w '\n%{http_code}' \
    --connect-timeout 10 \
    --max-time 30 \
    --location "http://nemo.test/v1/deployment/model-deployments" \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d "{
      \"name\": \"${nim_name}\",
      \"namespace\": \"${nim_api_namespace}\",
      \"config\": {
        \"model\": \"${nim_api_namespace}/${nim_name}\",
        \"nim_deployment\": {
          \"image_name\": \"nvcr.io/nim/${nim_api_namespace}/${nim_name}\",
          \"image_tag\": \"${image_tag}\",
          \"pvc_size\": \"25Gi\",
          \"gpu\": 1,
          \"additional_envs\": {
            \"NIM_GUIDED_DECODING_BACKEND\": \"fast_outlines\"
          }
        }
      }
    }" || true)"

  http="${body##*$'\n'}"
  body="${body%$'\n'*}"

  if [[ ! "$http" =~ ^[0-9]+$ ]] || (( http < 200 || http >= 300 )); then
    err "NIM deploy request failed (HTTP ${http:-unknown}). Response:"
    printf '%s\n' "${body:-<empty>}" >&2
    die "Failed to submit NIM deployment request for $nim_name."
  fi

  log "NIM deployment request for $nim_name submitted."
}
