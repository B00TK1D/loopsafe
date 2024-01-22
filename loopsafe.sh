#!/bin/sh

if [ $# -ne 2 ] || [ $# -ne 3]; then
    echo "Invalid arguments provided."
    echo "Usage: $0 <original_port> <new_port> [remote_host]"
    exit 1
fi

trap 'iptables -D PREROUTING -t nat -p tcp --dport $1 -j REDIRECT --to-port $2 2>/dev/null; echo -e "\nDisabling port forwarding and exiting"; exit' SIGKILL SIGINT SIGTERM

FORWORDING_ENABLED=2
PROXY_PID=0
while true; do
    nc -z 127.0.0.1 $2
    if [ $? -eq 1 ]; then
        if [ $FORWORDING_ENABLED -ne 0 ]; then
            echo "Remote connection to $2:$3 is down. Disabling port forwarding..."
            iptables -D PREROUTING -t nat -p tcp --dport $1 -j REDIRECT --to-port $2 2>/dev/null
            kill $PROXY_PID 2>/dev/null
            FORWORDING_ENABLED=0
        fi
    else
        if [ $FORWORDING_ENABLED -ne 1 ]; then
            echo "Remote connection to $2:$3 is up. Enabling port forwarding..."
            if [ $# -eq 3 ]; then
                nc -lk $2 -c "nc $3 $2"
                PROXY_PID=$!
            fi
            iptables -A PREROUTING -t nat -p tcp --dport $1 -j REDIRECT --to-port $2 2>/dev/null
            FORWORDING_ENABLED=1
        fi
    fi
    sleep 1
done
