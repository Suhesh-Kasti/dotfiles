#!/bin/bash

# Check if running on Hyprland
if [ -n "$(pgrep -f hyprland)" ]; then

# Set dim timeout to 5 minutes
dim_timeout=200

# Set suspend timeout to 10 minutes
suspend_timeout=300

# Set hibernate timeout to 20 minutes
hibernate_timeout=1200

# Start swayidle

while true; do
swayidle \
    timeout $dim_timeout "sleep 0.5; swaylock" \
    timeout $suspend_timeout "systemctl suspend" \
    timeout $hibernate_timeout "systemctl hibernate" \
    before-sleep "killall swayidle" 

sleep 1 
done

fi
