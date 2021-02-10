#!/bin/bash
# World Possible DCYF-WA update script
# This script may be run multiple times, so all operations need to be idempotent

mydir=$(readlink -f $(dirname $0))
if [[ "$EUID" != 0 ]]; then
	echo "Requesting root privileges"
	exec sudo bash $(readlink -f $0)
	exit 1
fi

error_handler() {
	echo "Failure on line ${LINENO}"
	exit 1
}
trap error_handler ERR

systemctl enable --now ssh

pkexec --user Debian-gdm dbus-run-session gsettings set org.gnome.shell password-reset-allowed disable &>/dev/null

bash $mydir/content-cleanup.sh

echo "Starting WiFi setup..."
bash $mydir/setup-wifi.sh
