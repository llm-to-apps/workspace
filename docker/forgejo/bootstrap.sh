#!/usr/bin/env bash
set -euo pipefail

/usr/bin/entrypoint "$@" &
forgejo_pid="$!"

finish() {
  kill -TERM "$forgejo_pid" 2>/dev/null || true
  wait "$forgejo_pid" 2>/dev/null || true
}

trap finish TERM INT

for _ in $(seq 1 120); do
  if /usr/local/bin/gitea admin user list >/dev/null 2>&1; then
    break
  fi

  if ! kill -0 "$forgejo_pid" 2>/dev/null; then
    wait "$forgejo_pid"
    exit $?
  fi

  sleep 1
done

admin_user="${FORGEJO_ADMIN_USER:-root}"
admin_password="${FORGEJO_ADMIN_PASSWORD:-admin1234}"
admin_email="${FORGEJO_ADMIN_EMAIL:-root@example.local}"

if /usr/local/bin/gitea admin user list | awk 'NR > 1 {print $2}' | grep -Fxq "$admin_user"; then
  /usr/local/bin/gitea admin user change-password \
    --username "$admin_user" \
    --password "$admin_password"
else
  /usr/local/bin/gitea admin user create \
    --admin \
    --username "$admin_user" \
    --password "$admin_password" \
    --email "$admin_email" \
    --must-change-password=false
fi

wait "$forgejo_pid"
