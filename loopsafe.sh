#!/bin/sh

if [ $# -ne 4 ]; then
    echo "Invalid arguments provided."
    echo "Usage: ./loopsafe.sh <local_port> <remote_ip> <remote_port>"
fi


echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -j MASQUERADE

FORWORDING_ENABLED=0
while true; do
    nc -z $2 $3
    if $?; then
        if [ $FORWORDING_ENABLED -eq 1 ]; then
            echo "Remote connection to $2:$3 is down. Disabling port forwarding..."
            iptables -t nat -D PREROUTING -p tcp --dport $1 -j DNAT --to-destination $2:$3
            FORWORDING_ENABLED=0
        fi
    else
        if [ $FORWORDING_ENABLED -eq 0 ]; then
            echo "Remote connection to $2:$3 is up. Enabling port forwarding..."
            iptables -t nat -A PREROUTING -p tcp --dport $1 -j DNAT --to-destination $2:$3
            FORWORDING_ENABLED=1
        fi
    fi
done
