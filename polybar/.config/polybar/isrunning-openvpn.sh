#!/bin/sh

if [ "$(pgrep openvpn)" ]; then
    echo "Genbook"
else
    echo "vpn"
fi
