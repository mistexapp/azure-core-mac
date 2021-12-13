#!/bin/sh
Version=2

SerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

path="/tmp/IntuneAdmins"
speedtest_tgz="${path}/Speedtest/ookla-speedtest.tgz"
exec_file="${path}/Speedtest/speedtest"

mkdir -p $path/Speedtest

# Reques_time
timestamp=$(date +%s)
f_timestamp=$(date +%d-%m-%y_%H:%M)

#_____________________________________________________________________________________________________________
# Network

RunTest()
{
    test=$($path/Speedtest/speedtest --accept-license --format=json)
    echo $test
}

if test -f "$exec_file"; then
    resp=$(RunTest)
else 
    curl https://install.speedtest.net/app/cli/ookla-speedtest-1.0.0-macosx.tgz --output $path/Speedtest/ookla-speedtest.tgz
    tar -xvf $path/Speedtest/ookla-speedtest.tgz -C "${path}/Speedtest/"
    xattr -dr com.apple.quarantine $path/Speedtest/ookla-speedtest.tgz
    resp=$(RunTest)
fi

#by speedtest
download_speed=$(expr $(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['download']['bandwidth'])") / 125000)
upload_speed=$(expr $(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['upload']['bandwidth'])") / 125000)
user_isp=$(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['isp'])")
user_city=$(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['server']['location'])")
user_country=$(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['server']['country'])")
Local_ip=$(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['interface']['internalIp'])")
Public_ip=$(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['interface']['externalIp'])")
mac_addr=$(echo $resp | python3 -c "import sys, json; print(json.load(sys.stdin)['interface']['macAddr'])")


if [ "$download_speed" = 0 ]; then
    Local_ip=$(ipconfig getifaddr en0)
    Public_ip=$(curl http://ifconfig.me/ip)
    user_country=$(curl https://ipinfo.io/${Public_ip} | python3 -c "import sys, json; print(json.load(sys.stdin)['country'])" )
    user_city=$(curl https://ipinfo.io/${Public_ip} | python3 -c "import sys, json; print(json.load(sys.stdin)['city'])" )
    user_isp=$(curl https://ipinfo.io/${Public_ip} | python3 -c "import sys, json; print(json.load(sys.stdin)['org'])" )
    mac_addr=$(ifconfig en0 | awk '/ether/{print $2}')
fi

if [ $download_speed = "" ]; then
    $download_speed=0
fi

if [ $upload_speed = "" ]; then
    $upload_speed=0
fi
#_____________________________________________________________________________________________________________
generate()
{
    cat <<EOF
    Network,host=$SerialNumber version_network="$Version",download_speed="$download_speed",upload_speed="$upload_speed",user_isp="$user_isp",user_city="$user_city",user_country="$user_country",public_ip="$Public_ip",local_ip="$Local_ip",mac="$mac_addr" $timestamp
EOF
}

#_____________________________________________________________________________________________________________
status_code=$(curl -s --write-out "%{http_code}\n" --request POST \
"$url/api/v2/write?org=ITS&bucket=$bucket&precision=s" \
    --header "Authorization: Token $token" \
    --header "Content-Type: text/plain; charset=utf-8" \
    --header "Accept: application/json" \
    --data-binary "$(generate)"
    )

if [ "$status_code" -ne 204 ]; then
    echo "ERROR: Status:$status_code"
else
    echo "DONE. Status:$status_code"
fi

exit 0