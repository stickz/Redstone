#!/bin/sh
echo "Starting Redstone!"
sleep 1
/usr/bin/screen -A -m -d -S redstone1 ./srcds_run -console -game nucleardawn +map hydro -maxplayers 33 -ip 31.186.250.39 -port 27015 -steamport 4381 -timeout 10