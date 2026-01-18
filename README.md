# NAS Automount Utility for macOS

A bash utility to automatically check if your NAS (Network Attached Storage) is mounted on macOS, and mount it if it's not. The script can run at intervals and send notifications if the mount fails or drops.

## Features

- ✅ Automatic detection of mount status
- ✅ Automatic mounting when NAS is not available
- ✅ Support for SMB, AFP, and NFS shares
- ✅ macOS notification alerts on mount failure/success
- ✅ Logging of all mount attempts and status
- ✅ Configurable via simple configuration file
- ✅ Can run manually, via cron, or launchd
- ✅ Test mode to check status without mounting
- ✅ Debug mode for troubleshooting

## Requirements

- macOS (tested on macOS 10.14+)
- Bash 3.2 or later (included with macOS)
- Network share accessible via SMB, AFP, or NFS

## Installation

### Quick Install

1. **Clone or download this repository:**
   ```bash
   git clone https://github.com/gfreiji/Automount-utility.git
   cd Automount-utility
   ```

2. **Copy the script to a location in your PATH:**
   ```bash
   sudo cp automount-nas.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/automount-nas.sh
   ```

3. **Create your configuration file:**
   ```bash
   cp .automount.conf.example ~/.automount.conf
   ```

4. **Edit the configuration file with your NAS details:**
   ```bash
   nano ~/.automount.conf
   ```
   
   Update these required fields:
   - `NAS_SHARE`: Your NAS share path (e.g., `smb://192.168.1.100/share`)
   - `MOUNT_POINT`: Where to mount (e.g., `/Volumes/NAS`)
   - `NAS_USERNAME`: Your username (if authentication required)
   - `NAS_PASSWORD`: Your password (if authentication required)

5. **Secure your configuration file:**
   ```bash
   chmod 600 ~/.automount.conf
   ```

## Configuration

Edit `~/.automount.conf` to customize the behavior:

```bash
# Required: SMB/AFP/NFS share path
NAS_SHARE="smb://your-nas-server/your-share"

# Required: Local mount point
MOUNT_POINT="/Volumes/NAS"

# Optional: Authentication
NAS_USERNAME="your-username"
NAS_PASSWORD="your-password"

# Optional: Logging
LOG_FILE="${HOME}/Library/Logs/automount-nas.log"

# Optional: Notifications
NOTIFY_ON_SUCCESS=false
NOTIFY_ON_FAILURE=true

# Optional: Log rotation
MAX_LOG_LINES=1000
```

### Share Path Examples

**SMB (Windows/Samba shares):**
```bash
NAS_SHARE="smb://nas-server/share"
NAS_SHARE="smb://192.168.1.100/media"
```

**AFP (Apple Filing Protocol):**
```bash
NAS_SHARE="afp://nas-server/share"
```

**NFS (Network File System):**
```bash
NAS_SHARE="nfs://nas-server/export/path"
```

## Usage

### Manual Execution

Run the script manually to check and mount your NAS:

```bash
automount-nas.sh
```

### Test Mode

Check if NAS is mounted without attempting to mount:

```bash
automount-nas.sh -t
```

### Debug Mode

Run with verbose output for troubleshooting:

```bash
automount-nas.sh -d
```

### Custom Configuration File

Use a different configuration file:

```bash
automount-nas.sh -c /path/to/custom.conf
```

### Command Line Options

```
Usage: automount-nas.sh [OPTIONS]

OPTIONS:
    -c FILE     Use alternate configuration file (default: ~/.automount.conf)
    -h          Show help message
    -v          Show version information
    -t          Test mode: check mount status without attempting to mount
    -d          Debug mode: show verbose output
```

## Automatic Execution

### Option 1: Using launchd (Recommended for macOS)

Launchd is the native macOS way to run periodic tasks.

1. **Copy the example plist file:**
   ```bash
   cp com.automount.nas.plist.example ~/Library/LaunchAgents/com.automount.nas.plist
   ```

2. **Edit the plist file to match your installation path:**
   ```bash
   nano ~/Library/LaunchAgents/com.automount.nas.plist
   ```
   
   Update the path in `ProgramArguments` to match where you installed the script.

3. **Load the launch agent:**
   ```bash
   launchctl load ~/Library/LaunchAgents/com.automount.nas.plist
   ```

4. **Verify it's running:**
   ```bash
   launchctl list | grep automount
   ```

The default configuration checks every 5 minutes (300 seconds). You can modify the `StartInterval` in the plist file to change this.

**To unload/disable:**
```bash
launchctl unload ~/Library/LaunchAgents/com.automount.nas.plist
```

### Option 2: Using cron

While cron is deprecated on macOS in favor of launchd, you can still use it:

1. **Edit your crontab:**
   ```bash
   crontab -e
   ```

2. **Add a line to run every 5 minutes:**
   ```
   */5 * * * * /usr/local/bin/automount-nas.sh
   ```

## Monitoring and Logs

### View Logs

Check the log file to see mount attempts and status:

```bash
tail -f ~/Library/Logs/automount-nas.log
```

### Log Format

Logs include timestamps and severity levels:

```
[2026-01-18 10:30:00] [INFO] NAS is already mounted at /Volumes/NAS
[2026-01-18 10:35:00] [WARN] NAS is not mounted at /Volumes/NAS
[2026-01-18 10:35:01] [INFO] Attempting to mount smb://nas-server/share to /Volumes/NAS
[2026-01-18 10:35:02] [INFO] Successfully mounted smb://nas-server/share to /Volumes/NAS
```

### Notifications

macOS notifications will appear when:
- **Mount fails** (if `NOTIFY_ON_FAILURE=true`)
- **Mount succeeds** (if `NOTIFY_ON_SUCCESS=true`)

## Troubleshooting

### Issue: "Configuration file not found"

**Solution:** Create the configuration file:
```bash
cp .automount.conf.example ~/.automount.conf
nano ~/.automount.conf
```

### Issue: "Failed to mount"

**Possible causes:**
1. **Incorrect share path** - Verify the NAS is reachable:
   ```bash
   ping nas-server
   ```

2. **Wrong credentials** - Double-check username and password in config file

3. **Network not ready** - The script may run before network is fully connected. Increase the launchd interval or add a delay.

4. **Mount point permission issues** - Ensure you have permission to create the mount point

**Debug steps:**
```bash
# Run in debug mode
automount-nas.sh -d

# Try mounting manually
mount -t smbfs smb://username:password@nas-server/share /Volumes/NAS
```

### Issue: Mount works manually but not via launchd

**Solution:** Launchd runs with limited environment. Ensure:
1. The script path in the plist is absolute (not relative)
2. The PATH in the plist includes necessary directories
3. The config file uses absolute paths (not `~` or `$HOME`)

### Issue: "Operation not permitted" errors

**Solution:** Grant Full Disk Access to Terminal (or your script runner):
1. Open System Preferences → Security & Privacy → Privacy
2. Select "Full Disk Access"
3. Add Terminal (or the app running your script)

### Issue: Password in plain text

**Security concerns:** The configuration file stores passwords in plain text.

**Mitigation:**
1. Set strict file permissions:
   ```bash
   chmod 600 ~/.automount.conf
   ```

2. Consider using macOS Keychain (requires additional scripting):
   - Store password in Keychain
   - Use `security find-generic-password` to retrieve it

3. Use shares that don't require authentication if possible

## Security Considerations

1. **File Permissions:** Always set configuration file to be readable only by you:
   ```bash
   chmod 600 ~/.automount.conf
   ```

2. **Password Storage:** The configuration file contains plain text passwords. Consider:
   - Using network shares that don't require passwords
   - Restricting physical access to your Mac
   - Encrypting your home directory
   - Using macOS Keychain (advanced)

3. **Log Files:** Log files may contain sensitive information. Review and secure them appropriately.

## Advanced Usage

### Multiple NAS Shares

To mount multiple NAS shares, create separate configuration files and run the script multiple times:

```bash
automount-nas.sh -c ~/.automount-nas1.conf
automount-nas.sh -c ~/.automount-nas2.conf
```

For launchd, create multiple plist files with different labels.

### Custom Notifications

The script uses `osascript` for notifications. You can customize the notification sound by editing the script or adding custom notification handlers.

### Integration with Other Scripts

The script exits with status codes:
- `0`: Success (NAS is mounted)
- `1`: Failure (NAS is not mounted or mount failed)

Use this in your own scripts:

```bash
if automount-nas.sh -t; then
    echo "NAS is available"
    # Do something with mounted NAS
else
    echo "NAS is not available"
    # Handle offline case
fi
```

## Uninstallation

1. **Remove launchd job (if using):**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.automount.nas.plist
   rm ~/Library/LaunchAgents/com.automount.nas.plist
   ```

2. **Remove script:**
   ```bash
   sudo rm /usr/local/bin/automount-nas.sh
   ```

3. **Remove configuration and logs:**
   ```bash
   rm ~/.automount.conf
   rm ~/Library/Logs/automount-nas.log
   ```

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the need to keep NAS connections alive on macOS
- Built for macOS systems using native tools

## Changelog

### Version 1.0.0
- Initial release
- Support for SMB, AFP, and NFS shares
- macOS notifications
- Logging with rotation
- launchd integration
- Test and debug modes