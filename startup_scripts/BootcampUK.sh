#!/bin/sh
echo "Starting Bootcamp!"
sleep 1
/usr/bin/screen -A -m -d -S bootcamp1 ./srcds_run -console -game nucleardawn +map hydro -maxplayers 32 -ip 82.163.79.241 -port 27017 -steamport 4383 -timeout 10