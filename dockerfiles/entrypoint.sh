#!/bin/sh
set -e

BINARY_PATH=/opt/rel/unsplash_proxy/bin/unsplash_proxy

exec $BINARY_PATH "$@"
