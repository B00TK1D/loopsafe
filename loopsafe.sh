#!/bin/sh

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    echo "Invalid arguments provided."
    echo "Usage: $0 <original_port> <new_port> [remote_host]"
    exit 1
fi

FORWORDING_ENABLED=2
PROXY_PID=-1
PROXY_PORT=$2
REMOTE_HOST="127.0.0.1"
if [ $# -eq 3 ]; then
    REMOTE_HOST=$3
fi

trap 'kill $PROXY_PID 2>/dev/null; iptables -D PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $2 2>/dev/null; rm /tmp/.loopsafe-port-$$ 2>/dev/null; rm /tmp/.loopsafe-pipe-$$ 2>/dev/null; echo -e "\nDisabling port forwarding and exiting"; exit' SIGKILL 2>/dev/null
trap 'kill $PROXY_PID 2>/dev/null; iptables -D PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $2 2>/dev/null; rm /tmp/.loopsafe-port-$$ 2>/dev/null; rm /tmp/.loopsafe-pipe-$$ 2>/dev/null; echo -e "\nDisabling port forwarding and exiting"; exit' SIGNINT 2>/dev/null
trap 'kill $PROXY_PID 2>/dev/null; iptables -D PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $2 2>/dev/null; rm /tmp/.loopsafe-port-$$ 2>/dev/null; rm /tmp/.loopsafe-pipe-$$ 2>/dev/null; echo -e "\nDisabling port forwarding and exiting"; exit' SIGTERM 2>/dev/null

while true; do
    nc -z $REMOTE_HOST $2
    if [ $? -eq 1 ]; then
        if [ $FORWORDING_ENABLED -ne 0 ]; then
            echo "Remote connection to $3:$2 is down. Disabling port forwarding..."
            iptables -D PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
            kill $PROXY_PID 2>/dev/null
            PROXY_PID=-1
            rm /tmp/.loopsafe-port-$$ 2>/dev/null
            rm /tmp/.loopsafe-pipe-$$ 2>/dev/null
            FORWORDING_ENABLED=0
        fi
    else
        if [ $FORWORDING_ENABLED -ne 1 ]; then
            echo "Remote connection to $3:$2 is up. Enabling port forwarding..."
            if [ $# -eq 3 ]; then
                PROXY_PORT="0"
                mkfifo /tmp/.loopsafe-port-$$
                mkfifo /tmp/.loopsafe-pipe-$$
                cat /tmp/.loopsafe-pipe-$$ | nc $REMOTE_HOST $2 | nc -lkvp 0 > /tmp/.loopsafe-pipe-$$ 2>/tmp/.loopsafe-port-$$
                while [ "$PROXY_PORT" -eq "0" ]; do
                    PROXY_PORT=$(head -n 1 /tmp/.loopsafe-port-$$ | cut -d' ' -f4)
                done
                PROXY_PID=$!
            fi
            iptables -A PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $2 2>/dev/null
            FORWORDING_ENABLED=1
        fi
    fi
    sleep 1
done
