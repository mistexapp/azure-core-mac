#!/bin/sh
Version=2

SerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
Hostname=$(echo $HOSTNAME | sed -e "s/.local/${replace}/g")
Username=$(id -F)

#___________________________________________________________________________________________________________________________________________________________
# Reques_time
timestamp=$(date +%s)
f_timestamp=$(date +%d-%m-%y_%H:%M)

#___________________________________________________________________________________________________________________________________________________________
# OS details
OS_Name=$(sw_vers | grep "ProductName:" | awk '/ProductName/ {print $2}') 
OS_ProductName=$(sw_vers | grep "ProductVersion:" | awk '/ProductVersion/ {print $2}')
OS_Build=$(sw_vers | grep "BuildVersion:" | awk '/BuildVersion/ {print $2}')
OS_Uptime=$(system_profiler SPSoftwareDataType | grep "Time since boot:" | sed 's:.*boot.::' )
OS_Language=$(osascript -e 'user locale of (get system info)')
OS_InstalledDate=$((ls -l /var/db/.AppleSetupDone) | awk ' {print $6, $7, $8}' )

OS_Users0=$(ls /Users)
OS_Users=$((ls /Users) | tr '\n' ' ')
FileVault_Status=$(fdesetup status)
if [ "$FileVault_Status" = "FileVault is On." ]; then
    os_encryption=1
else
    os_encryption=0
fi

#_____________________________________________________________________________________________________________
# Hardware
# Hardware.RAM
RAM_Capacity=$(expr $(sysctl -n hw.memsize) / $((1024**3)))
RAM_Manufacturer="-"
Ram_Usage=$(echo $(ps -A -o %mem | awk '{mem += $1} END {print mem}') | awk '{print int($1)}')
RAM_Speed="-"

# Hardware.CPU
#CPU_Model=$(sysctl -n machdep.cpu.brand_string)
CPU_Model=$(echo "$(sysctl -n machdep.cpu.brand_string)" | sed -r 's/Intel(R) Core(TM)/Core/g')
CPU_Cores=$(sysctl -n machdep.cpu.core_count)
CPU_Threads=$(sysctl -n machdep.cpu.thread_count)
CPU_Usage=$(ps -axro pcpu | awk '{sum+=$1} END {print sum}')

# Hardware.Disks
#Disk=$(system_profiler SPNVMeDataType | grep -A4 "Apple SSD Controller:" | awk '/Capacity/ {print $2}')
Disk=$(echo "$(system_profiler SPNVMeDataType | grep -A4 "Apple SSD Controller:" | awk '/Capacity/ {print $2}')" | sed -r 's/,/./g')

#Hardware.LaptopModel
Laptop=$(system_profiler SPHardwareDataType | grep "Model Name:" | awk '/Name/ {print $3, $4, $5}' )
SerialNumber=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')

# Hardware.Battery
battery_capacity=$(system_profiler SPPowerDataType | grep "State of Charge (%):" | awk '/Charge/ {print $5}')
battery_charging=$(system_profiler SPPowerDataType | grep -A3 "Charge Information:" | grep "Charging:" | awk '/Charging/ {print $2}')
if [ "$battery_charging" = "No" ]; then
    battery_charging="Discharging"
else
    battery_charging="Charging"
fi

#_____________________________________________________________________________________________________________
generate2()
{
    cat <<EOF
    General,host=$SerialNumber hostname="$Hostname",username="$Username",serialnumber="$SerialNumber",version="$Version",laptop="$Laptop",encryption="$os_encryption" $timestamp
    CPU,host=$SerialNumber cpu_model="$CPU_Model",cpu_usage="$CPU_Usage",cpu_cores="$CPU_Cores",cpu_threads="$CPU_Threads" $timestamp
    Memory,host=$SerialNumber mem_capacity="$RAM_Capacity",mem_manufacturer="$RAM_Manufacturer",mem_usage="$Ram_Usage",mem_speed="$RAM_Speed" $timestamp
    Battery,host=$SerialNumber batt_charging="$battery_charging",batt_capacity="$battery_capacity" $timestamp
    Disk,host=$SerialNumber disks="$Disk" $timestamp
    OperationSystem,host=$SerialNumber os_name="$OS_Name",os_build="$OS_Build",os_product_name="$OS_ProductName",os_uptime="$OS_Uptime",os_language="$OS_Language",os_installed_date="$OS_InstalledDate" $timestamp
EOF
}

#_____________________________________________________________________________________________________________
curl --request POST \
"$url/api/v2/write?org=ITS&bucket=$bucket&precision=s" \
    --header "Authorization: Token $token" \
    --header "Content-Type: text/plain; charset=utf-8" \
    --header "Accept: application/json" \
    --data-binary "$(generate2)"

exit 0