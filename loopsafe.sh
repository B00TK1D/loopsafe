#!/bin/sh

if [ $# -ne 2 ]; then
    echo "Invalid arguments provided."
    echo "Usage: $0 <original_port> <new_port>"
    exit 1
fi

FORWORDING_ENABLED=2
while true; do
    nc -z 127.0.0.1 $2
    if [ $? -eq 1 ]; then
        if [ $FORWORDING_ENABLED -ne 0 ]; then
            echo "Remote connection to $2:$3 is down. Disabling port forwarding..."
            iptables -D PREROUTING -t nat -p tcp --dport $1 -j REDIRECT --to-port $2 2>/dev/null
            FORWORDING_ENABLED=0
        fi
    else
        if [ $FORWORDING_ENABLED -ne 1 ]; then
            echo "Remote connection to $2:$3 is up. Enabling port forwarding..."
            iptables -A PREROUTING -t nat -p tcp --dport $1 -j REDIRECT --to-port $2 2>/dev/null
            FORWORDING_ENABLED=1
        fi
    fi
    sleep 1
done
