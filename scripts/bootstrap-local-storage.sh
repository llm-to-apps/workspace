#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

ENV_FILE="${ENV_FILE:-.env}"
WEB_ENV_FILE="${WEB_ENV_FILE:-web/.env}"
MANAGER_READY_TIMEOUT_SECONDS="${MANAGER_READY_TIMEOUT_SECONDS:-180}"

env_value() {
  local file="$1"
  local key="$2"

  grep -E "^${key}=" "${file}" | tail -n 1 | cut -d '=' -f 2- | sed -E 's/^"(.*)"$/\1/' || true
}

set_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local tmp

  tmp="$(mktemp)"

  if grep -qE "^${key}=" "${file}"; then
    awk -v key="${key}" -v value="${value}" '
      BEGIN { replaced = 0 }
      $0 ~ "^" key "=" {
        if (!replaced) {
          print key "=" value
          replaced = 1
        }
        next
      }
      { print }
    ' "${file}" > "${tmp}"
  else
    cat "${file}" > "${tmp}"
    printf '\n%s=%s\n' "${key}" "${value}" >> "${tmp}"
  fi

  mv "${tmp}" "${file}"
}

json_field() {
  local field="$1"

  node -e '
    const field = process.argv[1]
    let input = ""
    process.stdin.setEncoding("utf8")
    process.stdin.on("data", chunk => input += chunk)
    process.stdin.on("end", () => {
      const value = JSON.parse(input)[field]
      if (typeof value !== "string" || !value) process.exit(1)
      process.stdout.write(value)
    })
  ' "${field}"
}

if [[ ! -f "${ENV_FILE}" ]]; then
  cp .env.example "${ENV_FILE}"
  echo "Created ${ENV_FILE} from .env.example"
fi

if [[ ! -f "${WEB_ENV_FILE}" ]]; then
  cp web/.env.example "${WEB_ENV_FILE}"
  echo "Created ${WEB_ENV_FILE} from web/.env.example"
fi

set -a
# shellcheck disable=SC1090
. "./${ENV_FILE}"
set +a

manager_port="${MANAGER_PORT:-8080}"
manager_url="${MANAGER_URL:-http://127.0.0.1:${manager_port}}"
bucket="$(env_value "${WEB_ENV_FILE}" STORAGE_S3_BUCKET)"
bucket="${bucket:-${STORAGE_S3_BUCKET:-os7-local-web}}"
user="${STORAGE_WEB_IAM_USER:-web-platform}"
deadline=$((SECONDS + MANAGER_READY_TIMEOUT_SECONDS))

while (( SECONDS < deadline )); do
  if curl -fsS "${manager_url}/health" >/dev/null 2>&1; then
    break
  fi

  sleep 2
done

if ! curl -fsS "${manager_url}/health" >/dev/null 2>&1; then
  cat >&2 <<MSG
Manager did not become ready at ${manager_url} within ${MANAGER_READY_TIMEOUT_SECONDS}s.

Check:
  docker stack services ${STACK_NAME:-os7}
  docker service logs ${STACK_NAME:-os7}_manager
MSG
  exit 1
fi

response=""
while (( SECONDS < deadline )); do
  if response="$(
    curl -fsS \
      -X POST "${manager_url}/storage/platform-bucket" \
      -H 'Accept: application/json' \
      -H 'Content-Type: application/json' \
      -d "{\"bucket\":\"${bucket}\",\"user\":\"${user}\"}" 2>/dev/null
  )"; then
    break
  fi

  sleep 3
done

if [[ -z "${response}" ]]; then
  cat >&2 <<MSG
Manager is ready, but local SeaweedFS storage was not provisioned within ${MANAGER_READY_TIMEOUT_SECONDS}s.

Check:
  docker service logs ${STACK_NAME:-os7}_manager
  docker service logs ${STACK_NAME:-os7}_seaweedfs
MSG
  exit 1
fi

access_key="$(printf '%s' "${response}" | json_field accessKeyId)"
secret_key="$(printf '%s' "${response}" | json_field secretAccessKey)"

set_env_value "${ENV_FILE}" STORAGE_S3_BUCKET "${bucket}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_ENDPOINT "${STORAGE_S3_ENDPOINT:-http://localhost:8333}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_INTERNAL_ENDPOINT "${STORAGE_S3_INTERNAL_ENDPOINT:-http://seaweedfs:8333}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_REGION "${STORAGE_S3_REGION:-us-east-1}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_BUCKET_PREFIX "${STORAGE_S3_BUCKET_PREFIX:-os7-local}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_BUCKET "${bucket}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_ACCESS_KEY_ID "${access_key}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_SECRET_ACCESS_KEY "${secret_key}"
set_env_value "${WEB_ENV_FILE}" STORAGE_S3_FORCE_PATH_STYLE "${STORAGE_S3_FORCE_PATH_STYLE:-true}"

echo "Bootstrapped local web SeaweedFS bucket ${bucket} and wrote scoped credentials to ${WEB_ENV_FILE}."
