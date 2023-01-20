#!/bin/bash
set -e

if [ "$PHP_MODULES" != "" ]; then
  for module in $PHP_MODULES; do
    docker-php-ext-enable "$module"
  done
fi

# Set memcached session save handle
if [ -n "$MEMCACHED" ]; then
  if [ -f "$PHP_INI_DIR"/conf.d/20-memcached.ini ]; then
    rm "$PHP_INI_DIR"/conf.d/20-memcached.ini
  fi

  if [ ! -f "$PHP_INI_DIR"/conf.d/docker-php-ext-memcached.ini ]; then docker-php-ext-enable memcached >/dev/null; fi

  IFSO=$IFS
  IFS=' ' read -ra BACKENDS <<<"${MEMCACHED}"
  for BACKEND in "${BACKENDS[@]}"; do
    SAVE_PATH="${SAVE_PATH}${BACKEND}?${MEMCACHED_CONFIG:-persistent=1&timeout=5&retry_interval=30},"
  done
  IFS=$IFSO

  cat <<EOF >>"$PHP_INI_DIR"/conf.d/20-memcached.ini
    session.save_handler = memcached
    session.save_path = "${SAVE_PATH}"
EOF
fi

# Run
if [[ -n "$1" ]]; then
  exec "${*}"
else
  exec apache2-foreground
fi
