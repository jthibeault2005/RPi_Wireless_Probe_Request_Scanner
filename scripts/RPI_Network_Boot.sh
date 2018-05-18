#!/bin/bash

createAdHocNetwork()
{
	local iface="$1"
	echo "Creating RPI Hotspot network"
	ifconfig $iface down
	ifconfig $iface 10.0.0.5 netmask 255.255.255.0 up
	systemctl start dnsmasq.service
	systemctl start hostapd.service
	echo -e "\nHotspot network created\n"
}

rcRedundancy()
{
	# Set local variables
	local ifaceint="$1"
	local ifacehot="$2"
	local con=false
	local ssids=( [0]="RTime" [1]="RSpace" [2]="Edge Of The World" )
	# Prep interface to scan for APs
	ifconfig $ifaceint down &&
	iwconfig $ifaceint mode Managed &&
	ifconfig $ifaceint up
	echo "Scanning for known WiFi networks on interface: $ifaceint"
	for ssid in "${ssids[@]}"
	do
		echo -e "\nChecking if SSID available: $ssid\n"
		if iwlist $ifaceint scan | grep "$ssid" > /dev/null; then
			echo "First WiFi in range has SSID:" $ssid
			con=true
			echo "Starting supplicant for WPA/WPA2"
			wpa_supplicant -B -i $ifaceint -c /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null 2>&1
			echo "Obtaining IP from DHCP"
			if dhclient -1 $ifaceint; then
				echo "Connected to WiFi"
				con=true
				break
			else
				echo "DHCP server did not respond with an IP lease DHCPOFFER"
				wpa_cli terminate
				break
			fi
		else
			echo "Not in range, WiFi with SSID:" $ssid
		fi
	done
	if ! $con; then
		createAdHocNetwork "$ifacehot"
	fi
}

connectWiFi()
{
	local iface="$1"
	local ssid="$2"
	# Prep interface to scan for APs
	ifconfig $iface down &&
	iwconfig $iface mode Managed &&
	ifconfig $iface up
	echo -e "\nChecking if SSID available: $ssid\n"
	if iwlist $iface scan | grep "$ssid" > /dev/null; then
		echo "First WiFi in range has SSID:" $ssid
		echo "Starting supplicant for WPA/WPA2"
		wpa_supplicant -B -i $iface -c /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null 2>&1
		echo "Obtaining IP from DHCP"
		if dhclient -1 $iface; then
			echo "Connected to WiFi"
		else
			echo "DHCP server did not respond with an IP lease DHCPOFFER"
			wpa_cli terminate
		fi
	else
		echo "Not in range, WiFi with SSID:" $ssid
	fi
}

downDNSAP()
{
	if [ "`systemctl is-active hostapd`" == "active" ]; then
		systemctl stop dnsmasq.service
		systemctl stop hostapd.service
	fi
	if [ "`systemctl is-enabled dnsmasq`" == "enabled" ]; then
		systemctl disable dnsmasq.service
		systemctl disable hostapd.service
	fi
}

dumpCap()
{
	local iface="$1"
	local chan="$2"
	# This order is important
	ifconfig $iface down &&
	iwconfig $iface mode Monitor &&
	ifconfig $iface up &&
	iwconfig $iface channel $chan &&
	screen -S dumpcap_probe_`echo $iface'_'$chan` -d -m /usr/bin/dumpcap -i $iface -I -f "wlan[0] == 0x40" -P -b filesize:5000 -b files:50 -w /root/Capture_RPI3/captured/"capture_probe_req_`date '+%Y-%m-%d_%H%M%S'`_`echo $iface'_'$chan`" &
}

captureX()
{
	local ifaces=()

	set -- "$@"
	while [ ! -z "$2" ]; do
		if [ "$1" == "HWLAN" ]; then
			# Syntax: createAdHocNetwork "interface"
			createAdHocNetwork "$2"
		else
			# Syntax: dumpCap "interface" "channel"
			dumpCap "$1" "$2"
			ifaces=("${ifaces[@]}" "$1")
		fi
		shift 2
	done

	# Watch files in screen session
	watchwlanX "${ifaces[@]}"
}

watchwlanX()
{
	#local beg="screen -S watch_captured -d -m watch -n .1 '"
	local beg="screen -S watch_captured -d -m watch -n .1 bash -c '"
	local end="' &"
	local begcom="du -b /root/Capture_RPI3/captured/capture_*_'"
	local endcom="'* | tail -n 1 &&"
	local coma=("date &&")

	for i in "$@"
	do
		coma=(${coma[@]} $begcom$i$endcom)
		#echo $begcom$i$endcom
	done

	coma=(${coma[@]} "echo")

	local command=$beg${coma[@]}$end
	echo "$command"
	$($command)
}

echo "================================="
echo "RPi Network Conf Bootstrapper"
echo "================================="

# Global Variables
INTWLAN=wlan0
DCAPWLAN=wlan1
DCAPWLAN2=wlan2
HOTWLAN=wlan3

while getopts ":a:bsw" opt; do
	case $opt in
		a)
			echo "createAHocNetwork used with parameter: $OPTARG" >&2
			createAdHocNetwork "$OPTARG"
			exit 0
			;;
		b)
			#######################################
			# These commands below are to run when
			# rc.local is run at boot time.
			#######################################
			downDNSAP
			# If can't connect to WiFi create your own
			rcRedundancy "$INTWLAN" "$HOTWLAN"
			exit 0
			;;
		s)
			echo "Shutting down hostapd and dnsmasq"
			downDNSAP
			exit 0
			;;
		w)
			ifacea=()
			ifacea=("wlan1")
			ifacea=("${ifacea[@]}" "wlan2")
			ifacea=("${ifacea[@]}" "wlan3")

			watchwlanX "${ifacea[@]}"

			exit 0
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
      			;;
	esac
done

#######################################
# These commands below are to run when
# rc.local is run at boot time.
#######################################

# Shuts down the hostapd and dnsmasq
downDNSAP

# Just connect and capture on wlan1
connectWiFi "$INTWLAN" "RTime"
captureX "$DCAPWLAN" 11 "$DCAPWLAN2" 02
gpxlogger -d -f /root/Capture_RPI3/gps/gps_`date '+%Y-%m-%d_%H%M%S'`.gpx


# Add this line to /etc/rc.local
#/root/Capture_RPI3/scripts/RPI_Network_Boot.sh
# Website of original Bootstrapper
#http://www.raspberryconnect.com/network/item/315-rpi3-auto-wifi-hotspot-if-no-internet
# Site used to for dumpcap
#http://www.algissalys.com/network-security/passive-packet-sniffing-on-wifi-connections
