# RPi_Wireless_Probe_Request_Scanner

## Purpose
The RPI_Network_Boot.sh script is the crux of this whole project.  The purpose is to set up a Raspberry Pi to switch a wireless card into monitor mode and listen for probe requests.  Probe requests are sent out by all wireless devices when they are looking for a known (a access point with pre-entered keys) device.  This probe request has information like the device's (your cell, laptop, roku) MAC or the SSID of a known access point.

## RPI_Network_Boot.sh
This is a script that starts the dumpcap program to collect probe requests.  This script is loaded automatically at startup, so you will find this line in the rc.local:
```
/root/Capture_RPI3/scripts/RPI_Network_Boot.sh
```

## Implementation

<!--
git add .
git commit -m "Working widget container Just need to add calls to server backend"
git remote add origin https://github.com/jthibeault2005/RPi_Wireless_Probe_Request_Scanner.git
git push origin master

git pull https://github.com/jthibeault2005/RPi_Wireless_Probe_Request_Scanner.git
-->
