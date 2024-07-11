#!/bin/bash

set -e

if [ "$1" = 'freeswitch' ]; then
    if [ ! -f "/etc/freeswitch/freeswitch.xml" ]; then
        mkdir -p /etc/freeswitch
        cp -varf /usr/share/freeswitch/conf/vanilla/* /etc/freeswitch/
    fi

    chown -R freeswitch:freeswitch /etc/freeswitch
    chown -R freeswitch:freeswitch /var/{run,lib,log}/freeswitch

    if [ -d /docker-entrypoint.d ]; then
        for f in /docker-entrypoint.d/*.sh; do
            [ -f "$f" ] && . "$f"
        done
    fi
    exec /usr/bin/freeswitch -u freeswitch -g freeswitch -nonat -c -run /tmp
fi

exec "$@"
