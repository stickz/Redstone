#!/bin/sh
echo "Starting Competitive!"
sleep 1
/usr/bin/screen -A -m -d -S competitive1 ./srcds_run -console -game nucleardawn +map hydro -maxplayers 32 -ip 82.163.79.241 -port 27015 -steamport 4381 -timeout 10