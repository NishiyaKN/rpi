cpu=$(</sys/class/thermal/thermal_zone0/temp)
echo "GPU => $(/usr/bin/vcgencmd measure_temp | cut -d '=' -f 2)"
echo "CPU => $((cpu/1000))'C"
