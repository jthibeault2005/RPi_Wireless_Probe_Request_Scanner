#!/bin/bash
#Special
cat /root/Capture_RPI3/filters/capture_filters_broad_malform | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' > /root/Capture_RPI3/filters/capture_filters &&
#cat /root/Capture_RPI3/filters/capture_filters_broad_malform | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' | sed -e s/$/\)/g | sed -e s/^/\!\(/g > /root/Capture_RPI3/filters/capture_filters &&

#SSID
cat /root/Capture_RPI3/filters/capture_filters_ssids | sed -e s/^/wlan_mgt\.ssid\ \=\=\ /g | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' >> /root/Capture_RPI3/filters/capture_filters &&
#cat /root/Capture_RPI3/filters/capture_filters_ssids | sed -e s/^/wlan_mgt\.ssid\ \=\=\ /g | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' | sed -e s/$/\)/g | sed -e s/^/\!\(/g >> /root/Capture_RPI3/filters/capture_filters &&

#MACs
cat /root/Capture_RPI3/filters/capture_filters_macs | sed -e s/^/wlan\.sa\ \=\=\ /g | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' >> /root/Capture_RPI3/filters/capture_filters &&
#cat /root/Capture_RPI3/filters/capture_filters_macs | sed -e s/^/wlan\.sa\ \=\=\ /g | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' | sed -e s/$/\)/g | sed -e s/^/\!\(/g >> /root/Capture_RPI3/filters/capture_filters &&

#End result
cat /root/Capture_RPI3/filters/capture_filters | sed -e :a -e '$!N; s/\n/\ \|\|\ /; ta' | sed -e s/$/\)/g | sed -e s/^/\!\(/g >> /root/Capture_RPI3/filters/capture_filters &&
       
tail -n 1 /root/Capture_RPI3/filters/capture_filters
