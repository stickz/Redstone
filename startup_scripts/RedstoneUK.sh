#!/bin/sh
echo "Starting Redstone!"
sleep 1
/usr/bin/screen -A -m -d -S redstone1 ./srcds_run -console -game nucleardawn +map hydro -maxplayers 32 -ip 82.163.79.241 -port 27025 -steamport 4382 -timeout 10