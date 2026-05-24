#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_FILE="${1:-${ROOT_DIR}/db/mock_data.sql}"

DB_HOST="${DB_HOST:-127.0.0.1}"
DB_PORT="${DB_PORT:-3306}"
DB_NAME="${DB_NAME_DEVELOPMENT:-qlpm_development}"
DB_USERNAME="${DB_USERNAME:-qlpm}"
DB_PASSWORD="${DB_PASSWORD:-qlpm}"
DOCKER_MODE="${DOCKER_MODE:-1}"

if [[ ! -f "${SQL_FILE}" ]]; then
  echo "Không tìm thấy file SQL: ${SQL_FILE}" >&2
  exit 1
fi

echo "==> Import mock data vào database: ${DB_NAME}"

if [[ "${DOCKER_MODE}" == "1" ]]; then
  echo "==> Chế độ Docker: chờ MySQL sẵn sàng..."
  for _ in $(seq 1 40); do
    if docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 -u"${DB_USERNAME}" -p"${DB_PASSWORD}" --silent >/dev/null 2>&1; then
      break
    fi
    sleep 2
  done

  if ! docker compose exec -T mysql mysqladmin ping -h 127.0.0.1 -u"${DB_USERNAME}" -p"${DB_PASSWORD}" --silent >/dev/null 2>&1; then
    echo "MySQL chưa sẵn sàng trong container mysql." >&2
    exit 1
  fi

  echo "==> Nạp dữ liệu từ: ${SQL_FILE}"
  docker compose exec -T mysql mysql -u"${DB_USERNAME}" -p"${DB_PASSWORD}" "${DB_NAME}" < "${SQL_FILE}"
else
  echo "==> Chế độ host: ${DB_HOST}:${DB_PORT}"
  mysql --protocol=TCP \
    -h"${DB_HOST}" \
    -P"${DB_PORT}" \
    -u"${DB_USERNAME}" \
    -p"${DB_PASSWORD}" \
    "${DB_NAME}" < "${SQL_FILE}"
fi

echo "==> Hoàn tất import mock data."
