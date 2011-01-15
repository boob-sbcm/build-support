#!/bin/sh

[[ -f /etc/paths.d/XQuartz ]] && rm /etc/paths.d/XQuartz 
[[ -f /etc/manpaths.d/XQuartz ]] && rm /etc/manpaths.d/XQuartz 

[[ -d /opt/X11/include/libpng12 ]] && rm -rf /opt/X11/include/libpng12
[[ -f /opt/X11/bin/libpng12-config ]] && rm /opt/X11/bin/libpng12-config

[[ -d /opt/X11/include/libpng14 ]] && rm -rf /opt/X11/include/libpng14
[[ -f /opt/X11/bin/libpng14-config ]] && rm /opt/X11/bin/libpng14-config

# Load the privileged_startx daemon
/bin/launchctl unload -w /Library/LaunchDaemons/org.macosforge.xquartz.privileged_startx.plist
/bin/launchctl load -w /Library/LaunchDaemons/org.macosforge.xquartz.privileged_startx.plist

# Cache system fonts
/opt/X11/bin/font_cache --force --system

exit 0
