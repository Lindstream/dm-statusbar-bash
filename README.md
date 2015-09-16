Dream Machine: Statusbar 
==============================
A DWM-statusbar written in Bash. 

**Keeps track of:**
* Currently connected vpn
* Bluetooth status
* Wifi status & network name
* Sound (level & mute-status)
* Battery status (discharging/charging, level)

Keeping track of openvpn
----------
* Open or fork /etc/systemd/system/openvpn.service
* Add the following to [Service]:  
```
ExecStartPre=/bin/bash -c "mkdir -p /tmp/.sysutils && echo %i > /tmp/.sysutils/current_vpn && chmod 666 /tmp/.sysutils"
```

*About to rewrite this into C, keep a lookout for "dm-statusbar-ng" ;) *

