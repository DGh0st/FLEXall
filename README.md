# FLEXall
Another FLEX loader that can be activated using long press on status bar or long three finger press anywhere.

## Whitelist Processes
FLEXall has the ability to be restricted from being loaded in specific processes, which can be specified by adding the following in `/var/mobile/Library/Preferences/com.dgh0st.flexall.whitelist.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist SYSTEM "file://localhost/System/Library/DTDs/PropertyList.dtd">
<plist version="1.0">
<dict>
	<key>whitelist</key>
	<array>
		<string>process.bundle.identifier</string>
	</array>
</dict>
```
