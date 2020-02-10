# FLEXall
Another FLEX loader that can be activated using long press on status bar or long three finger press anywhere.

## Blacklist Processes
FLEXall has the ability to not be loaded in specific processes, which can be specified by adding the following in `/var/mobile/Library/Preferences/com.dgh0st.flexall.blacklist.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>blacklist</key>
	<array>
		<string>process.bundle.identifier</string>
	</array>
</dict>
```
By default Snapchat is blacklisted to reduce the chances of getting banned.
