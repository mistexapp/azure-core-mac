#!/bin/sh
version_software=2

SerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

#___________________________________________________________________________________________________________________________________________________________
# Reques_time
timestamp=$(date +%s)
f_timestamp=$(date +%d-%m-%y_%H:%M)

cd /Applications
files=(*.app)

string="Software,host=$SerialNumber version_software='$version_software',"
for file in "${files[@]}"; do
    value=`plutil -p "/Applications/$file/Contents/Info.plist" | grep CFBundleShortVersionString`
    #echo "${file//.app/}: ${value##*>}" | tr -d '"'
    app=$(echo "${file//.app/}" | tr -d ' ' | tr -d '.')
    app_ver=$(echo "${value##*>}" | tr -d '"' | tr -d ' ')
    string+="$app='$app_ver',"
done
string+=" $timestamp"
software=$(echo $string | sed -e "s/, $timestamp/ $timestamp/g")

#_____________________________________________________________________________________________________________
status_code=$(curl -s --write-out "%{http_code}\n" --request POST \
"$url/api/v2/write?org=ITS&bucket=$bucket&precision=s" \
    --header "Authorization: Token $token" \
    --header "Content-Type: text/plain; charset=utf-8" \
    --header "Accept: application/json" \
    --data-binary "$software"
    )

if [ "$status_code" -ne 204 ]; then
    echo "ERROR: Status:$status_code"
else
    echo "DONE. Status:$status_code"
fi

exit 0