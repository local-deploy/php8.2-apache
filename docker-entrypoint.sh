#!/bin/bash
set -e

if [ "$PHP_MODULES" != "" ]; then
  for module in $PHP_MODULES; do
    docker-php-ext-enable "$module"
  done
fi

# Run
if [[ -n "$1" ]]; then
  exec "${*}"
else
  exec apache2-foreground
fi
