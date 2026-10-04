#!/bin/sh
echo "starting with $(cat /etc/app/config.json)"
exec "$@"
