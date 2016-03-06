#!/bin/sh
echo "Starting Bootcamp!"
sleep 1
/usr/bin/screen -A -m -d -S bootcamp1 ./srcds_run -console -game nucleardawn +map hydro -maxplayers 33 -ip 31.186.250.39 -port 27017 -steamport 4382 -timeout 10