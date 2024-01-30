#!/bin/sh

if [ $# -ne 2 ] && [ $# -ne 3 ]; then
    echo "Invalid arguments provided."
    echo "Usage: $0 <original_port> <new_port> [remote_host]"
    exit 1
fi

# Ensure dependancies are installed
UPDATED=0

if ! $(which ncat > /dev/null); then
    echo "Installing ncat..."
    sudo apt-get update >/dev/null 2>&1
    UPDATED=1
    sudo apt-get install -y ncat >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to install ncat.  Please install it manually and try again."
        exit 1
    fi
fi

if ! $(which iptables > /dev/null); then
    echo "Installing iptables..."
    if [ $UPDATED -eq 0 ]; then
        sudo apt-get update >/dev/null 2>&1
    fi
    sudo apt-get install -y iptables >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Failed to install iptables.  Please install it manually and try again."
        exit 1
    fi
fi

trap 'iptables -D PREROUTING -t nat -p tcp ! -s "$REMOTE_HOST" --dport "$1" -j REDIRECT --to-port "$PROXY_PORT" 2>/dev/null; kill "$PROXY_PID" 2>/dev/null; echo " Disabling port forwarding and exiting"; exit' KILL 2>/dev/null
trap 'iptables -D PREROUTING -t nat -p tcp ! -s "$REMOTE_HOST" --dport "$1" -j REDIRECT --to-port "$PROXY_PORT" 2>/dev/null; kill "$PROXY_PID" 2>/dev/null; echo " Disabling port forwarding and exiting"; exit' INT 2>/dev/null
trap 'iptables -D PREROUTING -t nat -p tcp ! -s "$REMOTE_HOST" --dport "$1" -j REDIRECT --to-port "$PROXY_PORT" 2>/dev/null; kill "$PROXY_PID" 2>/dev/null; echo " Disabling port forwarding and exiting"; exit' TERM 2>/dev/null


FORWORDING_ENABLED=2
PROXY_PORT=$2
REMOTE_HOST="127.0.0.1"
if [ $# -eq 3 ]; then
    REMOTE_HOST=$3
fi

NCAT="$(which ncat)"

while true; do
    ncat -z $REMOTE_HOST $2
    if [ $? -eq 1 ]; then
        if [ $FORWORDING_ENABLED -ne 0 ]; then
            echo "Remote connection to $3:$2 is down. Disabling port forwarding..."
            iptables -D PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $PROXY_PORT 2>/dev/null
            kill $PROXY_PID 2>/dev/null
            PROXY_PID=-1
            FORWORDING_ENABLED=0
        fi
    else
        if [ $FORWORDING_ENABLED -ne 1 ]; then
            echo "Remote connection to $3:$2 is up. Enabling port forwarding..."
            if [ $# -eq 3 ]; then
                PROXY_PORT=""
                ncat -lkp 0 -e "$NCAT $REMOTE_HOST $2" &
                PROXY_PID=$!
                while [ "$PROXY_PORT" = "" ]; do
                    PROXY_PORT=$(lsof -a -itcp -p $PROXY_PID | tail -n 1 | cut -d':' -f2 | cut -d' ' -f1)
                done
                echo "Proxy port is $PROXY_PORT"
            fi
            iptables -I PREROUTING -t nat -p tcp ! -s $REMOTE_HOST --dport $1 -j REDIRECT --to-port $PROXY_PORT
            FORWORDING_ENABLED=1
        fi
    fi
    sleep 2
done
