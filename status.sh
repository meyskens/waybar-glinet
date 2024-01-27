#!/bin/bash

# Configuration
PASS=""
carrierSuffixStrip="Orange B" # strips last part to prevent double carrier name
SUBNET="192.168.8."

# exit if IP of host is not in our mobile subnet
if [[ $(hostname -i | grep -c $SUBNET) -eq 0 ]]; then
    exit 0
fi

# get challenge and login

# https://web.archive.org/web/20230909030858/https://dev.gl-inet.com/router-4.x-api/
challenge=$(curl -s 'http://'"$SUBNET"'1/rpc' -X POST -H 'Accept: application/json, text/plain, */*' -H 'Content-Type: application/json;charset=utf-8' --data-raw '{"jsonrpc":"2.0","id":7,"method":"challenge","params":{"username":"root"}}')
alg=$(echo "$challenge" | jq -r .result.alg)
salt=$(echo "$challenge" | jq -r .result.salt)
nonce=$(echo "$challenge" | jq -r .result.nonce)
cipherPassword=$(openssl passwd -$alg -salt "$salt" "$PASS")
hash=$(echo -n "root:$cipherPassword:$nonce" | md5sum | cut -d ' ' -f 1)

login_response=$(curl -s 'http://'"$SUBNET"'1/rpc' -X POST -H 'Accept: application/json, text/plain, */*' -H 'Content-Type: application/json;charset=utf-8' --data-raw '{"jsonrpc":"2.0","id":8,"method":"login","params":{"username":"root","hash":"'"$hash"'"}}')
sid=$(echo "$login_response" | jq -r .result.sid)

if [[ "$sid" == "null" ]]; then
    echo "Login failed"
    exit 1
fi

device_info=$(curl -s 'http://'"$SUBNET"'1/rpc' -X POST -H 'Accept: application/json, text/plain, */*' -H 'Content-Type: application/json;charset=utf-8' -H "Cookie: Admin-Token=$sid" -H 'Sec-GPC: 1' --data-raw '{"jsonrpc":"2.0","id":7,"method":"call","params":["'"$sid"'","system","get_status",{}]}')
cell_info=$(curl -s 'http://'"$SUBNET"'1/rpc' -X POST -H 'Accept: application/json, text/plain, */*' -H 'Content-Type: application/json;charset=utf-8' -H "Cookie: Admin-Token=$sid" -H 'Sec-GPC: 1' --data-raw '{"jsonrpc":"2.0","id":15,"method":"call","params":["'"$sid"'","modem","get_status",{}]}')

# get battery satus from json using jq

battery_status=$(echo "$device_info" | jq -r '.result.system.mcu.charge_percent')
temperature=$(echo "$device_info" | jq -r '.result.system.mcu.temperature')
wifi_clients=$(echo "$device_info" | jq -r '.result.client[0].wireless_total')
carrier=$(echo "$cell_info" | jq -r .result.modems[0].simcard.carrier)
network_type=$(echo "$cell_info" | jq -r .result.modems[0].simcard.signal.network_type)
sms_count=$(echo "$cell_info" | jq -r .result.new_sms_count)
rssi=$(echo "$cell_info" | jq -r .result.modems[0].simcard.signal.rssi)
strength=$(echo "$cell_info" | jq -r .result.modems[0].simcard.signal.strength)

carrier=${carrier%"$carrierSuffixStrip"}
# trim spaces, i know xargs hahahaha
carrier=$(echo "$carrier" | xargs)


echo "$carrier [$network_type] - $battery_status%"
echo "$temperature ℃ - $wifi_clients  - $sms_count  - RSSI: $rssi - Strength: $strength"
echo ""