#!/bin/bash

#############################################
# Color settings
#############################################

# Color refs from dwm
color_normal="\x01"         #/* 01 - base */
color_selected="\x03"       #/* 03 - active */
color_active="\x04"         #/* 04 - selected */
color_urgent="\x05"         #/* 05 - urgent */
color_error="\x06"          #/* 06 - error */

# Icons
icon_battery_0="\uE6F9"
icon_battery_20="\uE6C4"
icon_battery_40="\uE6C5"
icon_battery_60="\uE6C6"
icon_battery_80="\uE6C7"
icon_battery_full="\uE653"
icon_battery_charging="\uE6AB"
icon_battery_charging_full="\uE6AE"
icon_bluetooth_on="\uE6A8"
icon_bluetooth_off="\uE65E"
icon_vpn_on="\uE631"
icon_vpn_off="\uE6C0"
icon_wifi_on="\uE665"
icon_wifi_off="\uE632"
icon_sound_muted="\uE706"
icon_sound_0="\uE705"
icon_sound_1="\uE704"
icon_sound_2="\uE703"
icon_sound_3="\uE702"

#################################################
#
# Helpers (ref. v.1.0)
#
#################################################
update_data(){
# Battery
BATTERY_STATUS="$(cat /sys/class/power_supply/BAT0/status)"
BATTERY_LEVEL="$(cat /sys/class/power_supply/BAT0/capacity)"

# Wifi/Bt card identifyer 
case $(cat /sys/class/rfkill/rfkill0/name) in "hci0") BT_CID=0; WIFI_CID=1 ;; *) BT_CID=1; WIFI_CID=0;; esac

# Check if external display is connected
[[ -z $(xrandr -q | grep 'DP1 disconnected') ]] && EDISP=true || EDISP=false;

# Check mute status
SOUND_LEVEL="$(amixer -D pulse sget Master | tail -n1 | sed -r 's/.*\[(.*)%\].*/\1/')"
[[ $(amixer -D pulse sget Master | tail -n1 | cut -d " " -f8-9) == '[off]' ]] && SOUND_MUTED=true || SOUND_MUTED=false;

# BT state
[[ $(cat /sys/class/rfkill/rfkill$BT_CID/state) == 1 ]] && BT_ACTIVE=true || BT_ACTIVE=false;

# Wifi state
[[ $(cat /sys/class/rfkill/rfkill$WIFI_CID/state) == 1 ]] && WIFI_ACTIVE=true || WIFI_ACTIVE=false;

# Firewall state
FIREWALL_INACTIVE="$(systemctl is-active iptables.service)"
([[ $FIREWALL_INACTIVE == "unknown" ]] || [[ $FIREWALL_INACTIVE == "inactive" ]]) && FIREWALL_INACTIVE=true || FIREWALL_INACTIVE=false;

# VPN state
VPN_CURRENT="$(cat /tmp/.sysutils/current_vpn)" # set by systemd unit
VPN_ACTIVE="$(systemctl is-active openvpn@$VPN_CURRENT)"
([[ $VPN_ACTIVE == "unknown" ]] || [[ $VPN_ACTIVE == "inactive" ]]) && VPN_ACTIVE=false || VPN_ACTIVE=true;
}

#################################################
#
# Dirty notifications (ACPI it now.. you lazy bastard!?)
#
#################################################
notify_battery(){
  if [ -f /tmp/.sysutils/battery_warning ]; then
    old_stamp="$(cat /tmp/.sysutils/battery_warning)"
    time_diff=$(($(timestamp) - $old_stamp))
    if [[ $time_diff -ge 300 ]]; then
      echo $(timestamp) > /tmp/.sysutils/battery_warning
      dunstify --urgency=critical "Battery low\!" "Please connect charger"   
    fi
  else
      echo $(timestamp) > /tmp/.sysutils/battery_warning
      dunstify --urgency=critical "Battery low\!" "Please connect charger"   
  fi
}

#################################################
#
# Status functions
#
#################################################
print_firewall() {
    if $FIREWALL_INACTIVE; then 
        echo -ne "FIREWALL DOWN! "
    fi
}

print_battery(){
    case $BATTERY_STATUS in 
      "Full") b_icon=$icon_battery_charging_full; b_level=100 ;;
      "Charging") b_icon=$icon_battery_charging ;; 
      "Discharging") 
        case $BATTERY_LEVEL in
            [0-9]) b_icon=$icon_battery_0; notify_battery ;; 
            [1-2][0-9]) b_icon=$icon_battery_20 ;;
            [3-4][0-9]) b_icon=$icon_battery_40 ;;
            [5-6][0-9]) b_icon=$icon_battery_60 ;;
            [7-8][0-9]) b_icon=$icon_battery_80 ;;
            *) b_icon=$icon_battery_full ;;
        esac
      ;;
    esac
    echo -ne "${b_icon}"
}

print_bluetooth(){
    if $BT_ACTIVE; then
        bt_icon=$icon_bluetooth_on
    else 
        bt_icon=$icon_bluetooth_off
    fi
    echo -ne "${bt_icon}"
}

print_vpn(){
    
    if $VPN_ACTIVE; then
        vpn_icon=$icon_vpn_on
        vpn_color=$color_normal
        vpn_status=$VPN_CURRENT
    else 
        vpn_icon=$icon_vpn_off
        vpn_color=$color_selected
        vpn_status="DISC!"
    fi
    echo -ne "${vpn_icon} ${vpn_status}"

}

print_wifi(){
    
    if $WIFI_ACTIVE; then
        wifi_icon=$icon_wifi_on
        wifi_color=$color_selected
        wifi_current="$(iwgetid -r)"
    else 
        wifi_icon=$icon_wifi_off
        wifi_color=$color_normal
    fi
    echo -ne "${wifi_icon}${wifi_current}"

}

print_sound() {
  if $SOUND_MUTED; then
    sound_icon=$icon_sound_muted
  else
    case $SOUND_LEVEL in
      [0-9]) sound_icon=$icon_sound_0 ;;
      [1-5][0-9]) sound_icon=$icon_sound_1 ;;
      [6-9][0-9]) sound_icon=$icon_sound_2 ;;
      *) sound_icon=$icon_sound_3 ;;
    esac
  fi
  echo -ne "${sound_icon}"
}

print_time() {
  echo -ne "$(date "+%H:%M")"
}

#################################################
#
# Output
#
#################################################
while sleep 1; do

# update system information
update_data

# draw it
xsetroot -name "\
$(echo -ne "${color_normal}")\
$(print_firewall)  \
$(print_vpn)  \
$(print_bluetooth)  \
$(print_wifi)  \
$(print_sound)  \
$(print_battery)   \
$(print_time)  "

done
